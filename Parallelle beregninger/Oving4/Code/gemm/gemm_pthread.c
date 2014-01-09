#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <pthread.h>
#include <time.h>
 


typedef struct{
    int n; //Number of elements that should be set
    float *C; //Pointer to the matrix

} cr_matrix_args;

typedef struct {
    int first_col;
    int last_col;
    int m;
    int k;
    int n;
    float *A;
    float *B;
    float *C;
} mm_args;

float random(){
    return ((float)rand())/((float)RAND_MAX);
}

void *insert_random(void *arg) {
    cr_matrix_args *matrix_args = (cr_matrix_args*) arg;
    for (int i = 0; i < matrix_args->n; i++) {
        (matrix_args->C)[i] = random();
    }
    free(arg);
    return NULL;
}


float* create_random_matrix(int m, int n){
    float* A = ( float*)malloc(sizeof( float)*m*n);

    for(int i = 0; i < m*n; i++){
        A[i] = random();
    }

    return A;
}

void *matrix_mult (void *args) {
    
    float alpha = -2;
    float beta = 1;

    mm_args *m_args = (mm_args*) args;
    int first_col = m_args->first_col;
    int last_col = m_args->last_col;
    float *C = m_args->C;
    float *A = m_args->A;
    float *B = m_args->B;
    int k = m_args->k;
    int m = m_args->m;
    int n = m_args->n;
    for(int x = first_col; x < last_col; x++){
        for(int y = 0; y < m; y++){
            C[y*n + x] *= beta;
            float temp_C = 0;
            for(int z = 0; z < k; z++){
                temp_C += A[y*k+z]*B[z*n + x];
            }
            C[y*n + x] += (temp_C*alpha);
        }
    }
    free(args);
    return NULL;
    
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


    srand(0);

    // Number of threads to use
    int nofThreads = 1;

    // Matrix sizes
    int m = 2;
    int n = 2;
    int k = 2;

    // Reading command line arguments
    if(argc != 5){
        printf("useage: gemm nofThreads m n k\n");
        exit(-1);
    }
    else{
        nofThreads = atoi(argv[1]);
        m = atoi(argv[2]);
        n = atoi(argv[3]);
        k = atoi(argv[4]);
    }

    // Initializing pThreads
    pthread_t *threads = malloc(sizeof(pthread_t)*nofThreads);

    // Initializing matrices

    float* A = create_random_matrix(m,k);
    float* B = create_random_matrix(k,n);
    float* C = create_random_matrix(m,n);
    
    // Performing computation
    int offset = 0;
    int size = n;
    for(int i = 0; i < nofThreads; i++){
        mm_args *arg = malloc(sizeof(mm_args));
        int subset = size/(nofThreads-i);
        arg->first_col = offset;
        arg->last_col = offset + subset;
        arg->m = m;
        arg->k = k;
        arg->n = n;
        arg->A = A;
        arg->B = B;
        arg->C = C;
        pthread_create(&threads[i], NULL, matrix_mult, (void*)arg);
        offset += subset;
        size -= subset;
    }
    
    for (int i = 0; i < nofThreads; i++) {
       pthread_join(threads[i], NULL);
    }


    // Printing result
    print_matrix(A, m,k);
    print_matrix(B, k,n);
    print_matrix(C, m,n);

    free(threads);
    return 0;

}
