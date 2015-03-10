#include <stdio.h>
#include <stdlib.h>
#include <float.h>
#include <math.h>
#include <cuda.h>

// Type for points
typedef struct{
    float x;    // x coordinate
    float y;    // y coordinate
    int cluster; // cluster this point belongs to
} Point;

// Type for centroids
typedef struct{
    float x;    // x coordinate
    float y;    // y coordinate
    int nPoints; // number of points in this cluster
} Centroid;

// Global variables
int nPoints;   // Number of points
int nClusters; // Number of clusters/centroids

Point* points;       // Array containig all points
Centroid* centroids; // Array containing all centroids


// Reading command line arguments
void parse_args(int argc, char** argv){
    if(argc != 3){
        printf("Useage: kmeans nClusters nPoints\n");
        exit(-1);
    }
    nClusters = atoi(argv[1]);
    nPoints = atoi(argv[2]);
}


// Create random point
Point create_random_point(){
    Point p;
    p.x = ((float)rand() / (float)RAND_MAX) * 1000.0 - 500.0;
    p.y = ((float)rand() / (float)RAND_MAX) * 1000.0 - 500.0;
    p.cluster = rand() % nClusters;
    return p;
}


// Create random centroid
Centroid create_random_centroid(){
    Centroid p;
    p.x = ((float)rand() / (float)RAND_MAX) * 1000.0 - 500.0;
    p.y = ((float)rand() / (float)RAND_MAX) * 1000.0 - 500.0;
    p.nPoints = 0;
    return p;
}




// Initialize random data
// Points will be uniformly distributed
void init_data(){
    points = (Point*)malloc(sizeof(Point)*nPoints);
    for(int i = 0; i < nPoints; i++){
        points[i] = create_random_point();
        if(i < nClusters){
            points[i].cluster = i;
        }
    }

    centroids = (Centroid*)malloc(sizeof(Centroid)*nClusters);
    for(int i = 0; i < nClusters; i++){
        centroids[i] = create_random_centroid();
    }
}

// Initialize random data
// Points will be placed in circular clusters 
void init_clustered_data(){
    float diameter = 500.0/sqrt(nClusters);

    centroids = (Centroid*)malloc(sizeof(Centroid)*nClusters);
    for(int i = 0; i < nClusters; i++){
        centroids[i] = create_random_centroid();
    }

    points = (Point*)malloc(sizeof(Point)*nPoints);
    for(int i = 0; i < nPoints; i++){
        points[i] = create_random_point();
        if(i < nClusters){
            points[i].cluster = i;
        }
    }

    for(int i = 0; i < nPoints; i++){
        int c = points[i].cluster;
        points[i].x = centroids[c].x + ((float)rand() / (float)RAND_MAX) * diameter - (diameter/2);
        points[i].y = centroids[c].y + ((float)rand() / (float)RAND_MAX) * diameter - (diameter/2);
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
float distance(Point a, Centroid b){
    float dx = a.x - b.x;
    float dy = a.y - b.y;

    return sqrt(dx*dx + dy*dy);
}

__global__ void increment_centroids(Point *points, Centroid *centroids,
        int nPoints, int nClusters) {
    int t_id = threadIdx.x;
    int global_tid = blockDim.x*blockIdx.x + t_id;
    Point *my_point = &points[global_tid];
    int c = my_point->cluster;
    atomicAdd(&(centroids[c].x), my_point->x);
    atomicAdd(&(centroids[c].y), my_point->y);
    atomicAdd(&(centroids[c].nPoints), 1);




}

__global__ void reassign_points(Point *points, Centroid *centroids, 
        int nPoints, int nClusters, int *updated) {

    const int MAX_CENT = 4096;
    __shared__ Centroid s_centroids[MAX_CENT]; //Max capacity in shared memory.
    int t_id = threadIdx.x;
    int global_tid = blockIdx.x*blockDim.x + t_id;
    Point *my_point = &points[global_tid];
    int nof_cent_to_load;
    int nof_cent_loaded = 0;
    
    float bestDistance = DBL_MAX;
    int bestCluster = -1;
    do {
        //Load centroids into shared memory
        if (nClusters > MAX_CENT) {
            nof_cent_to_load = MAX_CENT;
            nClusters -= MAX_CENT;
        }
        else nof_cent_to_load = nClusters;

        double interval = ceil((double)nof_cent_to_load/blockDim.x);
        if (t_id < nof_cent_to_load) {
            for (int i = interval*t_id; i < interval*(t_id+1); i++) {
                int index = nof_cent_loaded + i;
                s_centroids[i] = centroids[index];
            }
        }
        __syncthreads();
        for (int i = 0; i < nof_cent_to_load; i++) {
            float dx = my_point->x-s_centroids[i].x;
            float dy = my_point->y-s_centroids[i].y;
            float d = sqrt(dx*dx + dy*dy);
            if (d < bestDistance) {
                bestDistance = d;
                bestCluster = i + nof_cent_loaded; 
            }
        }
        nof_cent_loaded += nof_cent_to_load;
    } while (nClusters > MAX_CENT);
    if (bestCluster != my_point->cluster) {
        *updated = 1; 
    }
    my_point->cluster = bestCluster;

}


int main(int argc, char** argv){
    srand(5);
    parse_args(argc, argv);

    // Create random data, either function can be used.
    //init_clustered_data();
    init_data();
    size_t size_p = sizeof(Point)*nPoints;
    size_t size_c = sizeof(Centroid)*nClusters;

    Point *c_points;
    Centroid *c_centroids;
    int *c_updated;

    cudaMalloc((void**)&c_points, sizeof(Point)*nPoints);
    cudaMalloc((void**)&c_centroids, sizeof(Centroid)*nClusters);
    cudaMalloc((void**)&c_updated, sizeof(int));

    //There should be no more than 1024 threads pr. block. 
    int nofBlocks = nPoints/1024;
    // Iterate until no points are updated
    int updated = 1;
    while(updated){
        updated = 0;

        // Reset centroid positions
        for(int i = 0; i < nClusters; i++){
            centroids[i].x = 0.0;
            centroids[i].y = 0.0;
            centroids[i].nPoints= 0;
        }


        // cudaMemcpy(c_points, points, size_p, cudaMemcpyHostToDevice);
        // cudaMemcpy(c_centroids, centroids, size_c, cudaMemcpyHostToDevice);
        
        // increment_centroids<<<nofBlocks, nPoints/nofBlocks>>>(c_points, c_centroids, nPoints, nClusters);
        // cudaMemcpy(points, c_points, size_p, cudaMemcpyDeviceToHost);
        // cudaMemcpy(centroids, c_centroids, size_c, cudaMemcpyDeviceToHost);
        
        //Compute new centroids positions
        for(int i = 0; i < nPoints; i++){
            int c = points[i].cluster;
            centroids[c].x += points[i].x;
            centroids[c].y += points[i].y;
            centroids[c].nPoints++;
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

        //reassign points
        cudaMemcpy(c_points, points, size_p, cudaMemcpyHostToDevice);
        cudaMemcpy(c_centroids, centroids, size_c, cudaMemcpyHostToDevice);
        cudaMemcpy(c_updated, &updated, sizeof(int), cudaMemcpyHostToDevice);

        reassign_points<<<nofBlocks, nPoints/nofBlocks>>>(c_points, c_centroids, nPoints, nClusters, c_updated);
        cudaMemcpy(points, c_points, size_p, cudaMemcpyDeviceToHost);
        cudaMemcpy(centroids, c_centroids, size_c, cudaMemcpyDeviceToHost);
        cudaMemcpy(&updated, c_updated, sizeof(int), cudaMemcpyDeviceToHost);
        
    }
    cudaFree(c_points);
    cudaFree(c_centroids);
    cudaFree(c_updated);
    print_data_to_file(1);
}
