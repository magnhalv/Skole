#include <stdio.h>
#include <stdlib.h>
#include <float.h>
#include <math.h>
#include <pthread.h>

// Type for points
typedef struct{
    double x;    // x coordinate
    double y;    // y coordinate
    int cluster; // cluster this point belongs to
} Point;

// Type for centroids
typedef struct{
    double x;    // x coordinate
    double y;    // y coordinate
    int nPoints; // number of points in this cluster
    pthread_mutex_t mutex; //Added mutex for writing. 
} Centroid;

typedef struct {
    Centroid *centroids;
    int interval;
} centroid_args;

typedef struct {
    Point *points;
    int interval;
    int *updated;
} point_args;

// Global variables
int nPoints;   // Number of points
int nClusters; // Number of clusters/centroids
int nThreads;  // Number of threads to use

Point* points;       // Array containig all points
Centroid* centroids; // Array containing all centroids
Centroid* temp; //Used when switiching centroids array.
Centroid* centroids_next; /* Extra array used to 
                            update different values
                            in parallell */

//Barrier variables
int counter = 0;
pthread_mutex_t mutex;
pthread_cond_t cond_var;


// Reading command line arguments
void parse_args(int argc, char** argv){
    if(argc != 4){
        printf("Useage: kmeans nThreads nClusters nPoints\n");
        exit(-1);
    }
    nThreads = atoi(argv[1]);
    nClusters = atoi(argv[2]);
    nPoints = atoi(argv[3]);
}


// Create random point
Point create_random_point(){
    Point p;
    p.x = ((double)rand() / (double)RAND_MAX) * 1000.0 - 500.0;
    p.y = ((double)rand() / (double)RAND_MAX) * 1000.0 - 500.0;
    p.cluster = rand() % nClusters;
    return p;
}


// Create random centroid
Centroid create_random_centroid(){
    Centroid p;
    p.x = ((double)rand() / (double)RAND_MAX) * 1000.0 - 500.0;
    p.y = ((double)rand() / (double)RAND_MAX) * 1000.0 - 500.0;
    p.nPoints = 0;
    return p;
}


// Initialize random data
// Points will be uniformly distributed
void init_data(){
    points = malloc(sizeof(Point)*nPoints);
    for(int i = 0; i < nPoints; i++){
        points[i] = create_random_point();
        if(i < nClusters){
            points[i].cluster = i;
        }
    }

    centroids = malloc(sizeof(Centroid)*nClusters);
    centroids_next = malloc(sizeof(Centroid)*nClusters);
    for(int i = 0; i < nClusters; i++){
        centroids[i] = create_random_centroid();
    }
}

// Initialize random data
// Points will be placed in circular clusters 
void init_clustered_data(){
    double diameter = 500.0/sqrt(nClusters);

    centroids = malloc(sizeof(Centroid)*nClusters);
    for(int i = 0; i < nClusters; i++){
        centroids[i] = create_random_centroid();
    }

    points = malloc(sizeof(Point)*nPoints);
    for(int i = 0; i < nPoints; i++){
        points[i] = create_random_point();
        if(i < nClusters){
            points[i].cluster = i;
        }
    }

    for(int i = 0; i < nPoints; i++){
        int c = points[i].cluster;
        points[i].x = centroids[c].x + ((double)rand() / (double)RAND_MAX) * diameter - (diameter/2);
        points[i].y = centroids[c].y + ((double)rand() / (double)RAND_MAX) * diameter - (diameter/2);
        points[i].cluster = rand() % nClusters;
    }

    for(int i = 0; i < nClusters; i++){
        centroids[i] = create_random_centroid();
    }
}


// Print all points and centroids to standard output
void print_data(){
    for(int i = 0; i < nPoints; i++){
        printf("%f\t%f\t%d\t\n", points[i].x, points[i].y, points[i].cluster);
    }
    printf("\n\n");
    for(int i = 0; i < nClusters; i++){
        printf("%f\t%f\t%d\t\n", centroids[i].x, centroids[i].y, i);
    }
}

// Print all points and centroids to a file
// File name will be based on input argument
// Can be used to print result after each iteration
void print_data_to_file(int i){
    char filename[15];
    sprintf(filename, "%04d.dat", i);
    FILE* f = fopen(filename, "w+");

    for(int i = 0; i < nPoints; i++){
        fprintf(f, "%f\t%f\t%d\t\n", points[i].x, points[i].y, points[i].cluster);
    }
    fprintf(f,"\n\n");
    for(int i = 0; i < nClusters; i++){
        fprintf(f,"%f\t%f\t%d\t\n", centroids[i].x, centroids[i].y, i);
    }

    fclose(f);
}


// Computing distance between point and centroid
double distance(Point a, Centroid b){
    double dx = a.x - b.x;
    double dy = a.y - b.y;

    return sqrt(dx*dx + dy*dy);
}


void *reset_position(void *args) {
    centroid_args* my_args = (centroid_args*) args;
    // Reset centroid positions
    for(int i = 0; i < my_args->interval; i++){
        my_args->centroids[i].x = 0.0;
        my_args->centroids[i].y = 0.0;
        my_args->centroids[i].nPoints= 0;
    }

    //barrier
    pthread_mutex_lock(&mutex);
    counter++;
    if(counter == nThreads+1){
    counter = 0;
    pthread_cond_broadcast(&cond_var);
    } else{
    while(pthread_cond_wait(&cond_var, &mutex)!=0);
    }
    pthread_mutex_unlock(&mutex);


    free(args);
    pthread_exit(NULL);
}

void *calculate_new_centroids(void *args) {
    centroid_args* my_args = (centroid_args*) args;
    for(int i = 0; i < my_args->interval; i++){
        // If a centroid lost all its points, we give it a random position
        // (to avoid dividing by 0)
        if(my_args->centroids[i].nPoints == 0){
            my_args->centroids[i] = create_random_centroid();
        }
        else{
            my_args->centroids[i].x /= my_args->centroids[i].nPoints;
            my_args->centroids[i].y /= my_args->centroids[i].nPoints;
        }
    }
    free(args);
    
    //barrier
    pthread_mutex_lock(&mutex);
    counter++;
    if(counter == nThreads+1){
    counter = 0;
    pthread_cond_broadcast(&cond_var);
    } else{
    while(pthread_cond_wait(&cond_var, &mutex)!=0);
    }
    pthread_mutex_unlock(&mutex);

    pthread_exit(NULL);
    
}

void *reassign_points (void *args) {
    point_args *my_args = (point_args*) args;

    for(int i = 0; i < my_args->interval; i++){
        double bestDistance = DBL_MAX;
        int bestCluster = -1;

        for(int j = 0; j < nClusters; j++){
            double d = distance(my_args->points[i], centroids[j]);
            if(d < bestDistance){
                bestDistance = d;
                bestCluster = j;
            }
        }

        // If one point got reassigned to a new cluster, we have to do another iteration
        if(bestCluster != my_args->points[i].cluster){
            *(my_args->updated) = 1;
        }
        my_args->points[i].cluster = bestCluster;
        //Lock the spesific memory for writing.
        pthread_mutex_lock(&(centroids_next[bestCluster].mutex));
        centroids_next[bestCluster].x += my_args->points[i].x;
        centroids_next[bestCluster].y += my_args->points[i].y;
        centroids_next[bestCluster].nPoints++;
        pthread_mutex_unlock(&(centroids_next[bestCluster].mutex));
    }
    
    free(args);
    //barrier
    pthread_mutex_lock(&mutex);
    counter++;
    if(counter == nThreads+1){
    counter = 0;
    pthread_cond_broadcast(&cond_var);
    } else{
    while(pthread_cond_wait(&cond_var, &mutex)!=0);
    }
    pthread_mutex_unlock(&mutex);
    pthread_exit(NULL);

}

int main(int argc, char** argv){
    



    srand(0);
    

    parse_args(argc, argv);
    pthread_t thread_handles[nThreads];
    int first_threads;
    int sec_threads;
    first_threads = nThreads/2;
    sec_threads = nThreads - first_threads;

    // Create random data, either function can be used.
    //init_clustered_data();
    init_data();


    // Iterate until no points are updated
    int updated = 1;
    
    for(int i = 0; i < nClusters; i++){
            centroids[i].x = 0.0;
            centroids[i].y = 0.0;
            centroids[i].nPoints= 0;
        }


       // Compute new centroids positions
    for(int i = 0; i < nPoints; i++){
        int c = points[i].cluster;
        centroids[c].x += points[i].x;
        centroids[c].y += points[i].y;
        centroids[c].nPoints++;
    }
    while(updated){
        updated = 0;

        int offset = 0;

        for(int i = 0; i < nClusters; i++){
            centroids_next[i].x = 0.0;
            centroids_next[i].y = 0.0;
            centroids_next[i].nPoints= 0;
        }
        
        for(int i = 0; i < nClusters; i++){
            // If a centroid lost all its points, we give it a random position
            // (to avoid dividing by 0)
            if(centroids[i].nPoints == 0){
                centroids[i] = create_random_centroid();
            }
            else{
                centroids[i].x /= centroids[i].nPoints;
                centroids[i].y /= centroids[i].nPoints;
            }
        }


        //Reassign points to closest centroid
        offset = 0;
        for (int thread = 0; thread < nThreads; thread++) {
            point_args* t_args = malloc(sizeof(point_args));
            int interval = (nPoints-offset)/(nThreads-thread);
            t_args->points = &points[offset];
            t_args->interval = interval;
            t_args->updated = &updated;
            pthread_create(&thread_handles[thread+first_threads], NULL, 
                reassign_points, (void*) t_args);
            offset += interval;

        }

        pthread_mutex_lock(&mutex);
        counter++;
        if(counter == nThreads+1){
        counter = 0;
        pthread_cond_broadcast(&cond_var);
        } else{
        while(pthread_cond_wait(&cond_var, &mutex)!=0);
        }
        pthread_mutex_unlock(&mutex);
        
        temp = centroids;
        centroids = centroids_next;
        centroids_next = temp;
    }
    for(int i = 0; i < nClusters; i++){
        // If a centroid lost all its points, we give it a random position
        // (to avoid dividing by 0)
        if(centroids[i].nPoints == 0){
            centroids[i] = create_random_centroid();
        }
        else{
            centroids[i].x /= centroids[i].nPoints;
            centroids[i].y /= centroids[i].nPoints;
        }
    }
    print_data_to_file(1);
    free(centroids);
    free(centroids_next);
    pthread_exit(NULL);
}
