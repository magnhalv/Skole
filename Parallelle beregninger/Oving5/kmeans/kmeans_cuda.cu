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
Centroid* centroids_temp; //
Centroid* centroids_other; //Array used to reset the centroids, and increment them. 


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

Centroid create_random_centroid2(){
    Centroid p;
    p.x = 500.0;
    p.y = 500.0;
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
    centroids_other = (Centroid*)malloc(sizeof(Centroid)*nClusters);
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

 
__global__ void set_zero_and_calculate(Point *points, Centroid *centroids,
        Centroid *centroids_other) {
    int t_id = threadIdx.x;
    int local_blockId;  
    
    if (blockIdx.x >= gridDim.x/2) local_blockId = blockIdx.x - (gridDim.x/2);
    else local_blockId = blockIdx.x;


    int global_tid = blockDim.x*local_blockId + t_id;
    
    //Half of the blocks should reset the centroids in centroids_other 
    if (blockIdx.x >= gridDim.x/2) {
        Centroid my_centroid = centroids_other[global_tid];
        my_centroid.x = 0.0;
        my_centroid.y = 0.0;
        my_centroid.nPoints= 0;
        centroids_other[global_tid] = my_centroid; 
    }
    //Other half should calculate the new position for the centroids in the centroids array.
    else {
        Centroid my_centroid = centroids[global_tid];
        if(my_centroid.nPoints == 0){
            my_centroid.x = 500.0;
            my_centroid.y = 500.0;
            my_centroid.nPoints = 0;
        }
        else{
            my_centroid.x /= my_centroid.nPoints;
            my_centroid.y /= my_centroid.nPoints;
        }
        centroids[global_tid] = my_centroid;    
    }

}

__global__ void reassign_points(Point *points, Centroid *centroids, 
        Centroid *centroids_other, int nPoints, int nClusters, int *updated) {

    //Max capacity in shared memory.
    const int MAX_CENT = 4096;
    __shared__ Centroid s_centroids[MAX_CENT]; 
    
    //Get the ids
    int t_id = threadIdx.x;
    int global_tid = blockIdx.x*blockDim.x + t_id;
    
    //The point this thread is going to calculate.
    Point *my_point = &points[global_tid];
    
    //Number of centroids that will be loaded on the current iteration of the while-loop.
    int nof_cent_to_load;
    int nof_cent_loaded = 0;
    
    float bestDistance = DBL_MAX;
    int bestCluster = -1;
    do {
        //Calculate how many centroids that should be transfered to shared memory. 
        if (nClusters > MAX_CENT) {
            nof_cent_to_load = MAX_CENT;
            nClusters -= MAX_CENT;
        }
        else {
            nof_cent_to_load = nClusters;
            nClusters = 0;
        }
        //Load the centroids to shared memory
        double interval = ceil((double)nof_cent_to_load/blockDim.x);
        if (t_id < nof_cent_to_load) {
            for (int i = interval*t_id; i < interval*(t_id+1); i++) {
                int index = nof_cent_loaded + i;
                s_centroids[i] = centroids[index];
            }
        }
        //Make sure every thread is done loading.
        __syncthreads();
        //Calculate the best centroid. 
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
        __syncthreads();
    //Check if all centroids have been processed. If not, load the once that haven't.
    } while (nClusters > 0);
    if (bestCluster != my_point->cluster) {
        *updated = 1; 
    }
    my_point->cluster = bestCluster;
    //Add the location to the best centroid, using the centroid_other array. 
    atomicAdd(&(centroids_other[bestCluster].x), (float)my_point->x);
    atomicAdd(&(centroids_other[bestCluster].y), (float)my_point->y);
    atomicAdd(&(centroids_other[bestCluster].nPoints), 1);
}


int main(int argc, char** argv){
    srand(5);
    parse_args(argc, argv);

    // Create random data, either function can be used.
    //init_clustered_data();
    init_data();
    size_t size_p = sizeof(Point)*nPoints;
    size_t size_c = sizeof(Centroid)*nClusters;

    //Allocate space on the device
    Point *c_points;
    Centroid *c_centroids;
    Centroid *c_centroids_other;
    int *c_updated;

    cudaMalloc((void**)&c_points, sizeof(Point)*nPoints);
    cudaMalloc((void**)&c_centroids, sizeof(Centroid)*nClusters);
    cudaMalloc((void**)&c_centroids_other, sizeof(Centroid)*nClusters);
    cudaMalloc((void**)&c_updated, sizeof(int));

    //There should be no more than 1024 threads pr. block. 
    int nofBlocks = nPoints/1024;
    int nofBlocks_clusters;
    if (nClusters > 1024) nofBlocks_clusters = nClusters/1024;
    else nofBlocks_clusters = 1;
    // Iterate until no points are updated
    int updated = 1;

    //Compute new centroids positions on centroids
    for(int i = 0; i < nClusters; i++){
            centroids[i].x = 0.0;
            centroids[i].y = 0.0;
            centroids[i].nPoints= 0;
    }

    for(int i = 0; i < nPoints; i++){
        int c = points[i].cluster;
        centroids[c].x += points[i].x;
        centroids[c].y += points[i].y;
        centroids[c].nPoints++;
    }
    //Only need to copy the points once.
    cudaMemcpy(c_points, points, size_p, cudaMemcpyHostToDevice);
    
    while(updated){
        updated = 0;

        cudaMemcpy(c_centroids, centroids, size_c, cudaMemcpyHostToDevice);
        cudaMemcpy(c_centroids_other, centroids_other, size_c, cudaMemcpyHostToDevice);
        cudaMemcpy(c_updated, &updated, sizeof(int), cudaMemcpyHostToDevice);
        //Reset the positions to all the centroids in centroids_other
        //Calculate the new positions in centroids
        set_zero_and_calculate<<<2*nofBlocks_clusters, nClusters/nofBlocks_clusters>>>(c_points, c_centroids, c_centroids_other);
        
        

        //reassign points using centroids
        //For each point, add the position to the position of the respective centroid, using centroid_others
        reassign_points<<<nofBlocks, nPoints/nofBlocks>>>(c_points, c_centroids, c_centroids_other, nPoints, nClusters, c_updated);
        cudaMemcpy(&updated, c_updated, sizeof(int), cudaMemcpyDeviceToHost);
        cudaMemcpy(centroids, c_centroids, size_c, cudaMemcpyDeviceToHost);
        cudaMemcpy(centroids_other, c_centroids_other, size_c, cudaMemcpyDeviceToHost); 
        
        
        centroids_temp = centroids;
        centroids = centroids_other;
        centroids_other = centroids_temp;

    }
    cudaMemcpy(points, c_points, size_p, cudaMemcpyDeviceToHost);
    

    centroids = centroids_other;
    
    //Free memory on the device
    cudaFree(c_points);
    cudaFree(c_centroids);
    cudaFree(c_updated);
    cudaFree(c_centroids_other);
    print_data_to_file(1);
}
