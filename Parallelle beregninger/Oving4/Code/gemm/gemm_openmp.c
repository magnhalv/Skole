#include <stdio.h>
#include <stdlib.h>
#include <math.h>

float random(){
    return ((float)rand())/((float)RAND_MAX);
}


float* create_random_matrix(int m, int n){
    float* A = ( float*)malloc(sizeof( float)*m*n);
    for(int i = 0; i < m*n; i++){
        A[i] = random();
    }

    return A;
}


void print_matrix( float* A, int m, int n){

    int max_size = 10;
    if(m > max_size || n > max_size){
        printf("WARNING: matrix too large, only printing part of it\n");
        m = max_size;
        n = max_size;
    }

    for(int y = 0; y < m; y++){
        for(int x = 0; x < n; x++){
            printf("%.4f  ", A[y*n + x]);
        }
        printf("\n");
    }
    printf("\n");
}


int main(int argc, char** argv){

    // Number of threads to use
    int nThreads = 1;

    // Matrix sizes
    int m = 2;
    int n = 2;
    int k = 2;

    // Reading command line arguments
    if(argc != 5){
        printf("useage: gemm nThreads m n k\n");
        exit(-1);
    }
    else{
        nThreads = atoi(argv[1]);
        m = atoi(argv[2]);
        n = atoi(argv[3]);
        k = atoi(argv[4]);
    }

    // Initializing matrices
    float alpha = -2;
    float beta = 1;

    float* A = create_random_matrix(m,k);
    float* B = create_random_matrix(k,n);
    float* C = create_random_matrix(m,n);

    // Performing computation
    #pragma omp parallel for
    for(int x = 0; x < n; x++){
        for(int y = 0; y < m; y++){
            C[y*n + x] *= beta;
            for(int z = 0; z < k; z++){
                C[y*n + x] += alpha*A[y*k+z]*B[z*n + x];
            }
        }
    }

    // Printing result
    print_matrix(A, m,k);
    print_matrix(B, k,n);
    print_matrix(C, m,n);

}
