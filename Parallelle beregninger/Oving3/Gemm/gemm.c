#include <stdio.h>
#include <stdlib.h>
#include <complex.h>
#include <math.h>
#include <string.h>
#include <time.h>
#include <sys/time.h>
#include <cblas.h>

extern void gemm(complex float* A,
        complex float* B,
        complex float* C,
        int m,
        int n,
        int k,
        complex float alpha,
        complex float beta);


complex float random_complex(){
   return ((float)rand())/((float)RAND_MAX) + ((float)rand())/((float)RAND_MAX) * I;
}

void gemm_atlas(complex float * A,
        complex float* B,
        complex float* C,
        int m,
        int n,
        int k,
        complex float alpha,
        complex float beta){

    cblas_cgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, m, n, k, (void*)&alpha, A, k, B, n, (void*)&beta, C, n);
}


complex float* create_random_matrix(int m, int n){
    complex float* A = (complex float*)malloc(sizeof(complex float)*m*n);

    for(int i = 0; i < m*n; i++){
        A[i] = random_complex();
    }

    return A;
}

complex float* copy_matrix(complex float * A, int m, int n){
    complex float* B = (complex float*)malloc(sizeof(complex float)*m*n);
    memcpy(B, A, sizeof(complex float) * m * n);
    return B;
}


void print_matrix(complex float* A, int m, int n){

    int max_size = 10;
    if(m > max_size || n > max_size){
        printf("WARNING: matrix too large, only printing part of it\n");
        m = max_size;
        n = max_size;
    }

    for(int y = 0; y < m; y++){
        for(int x = 0; x < n; x++){
            printf("%.4f+%.4fI  ", creal(A[y*n + x]), cimag(A[y*n + x]));
        }
        printf("\n");
    }
    printf("\n");
}

float compare(complex float* A, complex float* B, int m, int n){

    float max = 0;
    for(int i = 0; i < m*n; i++){
        if(fabs(creal(A[i]) - creal(B[i])) > max){
            max = fabs(creal(A[i]) - creal(B[i]));
        }
        if(fabs(cimag(A[i]) - cimag(B[i])) > max){
            max = fabs(cimag(A[i]) - cimag(B[i]));
        }
    }

    return max;
}


int main(int argc, char** argv){

    int m = 2;
    int n = 2;
    int k = 2;

    if(argc == 1){
        printf("Using default values\n");
    }
    else if(argc == 4){
        m = atoi(argv[1]);
        n = atoi(argv[2]);
        k = atoi(argv[3]);
    }
    else{
        printf("useage: gemm m n k\n");
        exit(-1);
    }

    complex float alpha = -2 + 0.5 * I;
    complex float beta = 1 + -0.3 * I;

    complex float* A = create_random_matrix(m,k);
    complex float* B = create_random_matrix(k,n);
    complex float* C = create_random_matrix(m,n);
    complex float* D = copy_matrix(C,m,n);

    struct timeval start, end;

    gettimeofday(&start, NULL);
    gemm(A,B,C,m,n,k,alpha,beta);
    gettimeofday(&end, NULL);


    long int ms = ((end.tv_sec * 1000000 + end.tv_usec) - (start.tv_sec * 1000000 + start.tv_usec));
    double s = ms/1e6;
    printf("Time : %f s\n", s);

    gemm_atlas(A,B,D,m,n,k,alpha,beta);

    // For debugging
    // print_matrix(A, m,k);
    // print_matrix(B, k,n);
    // print_matrix(C, m,n);
    // print_matrix(D, m,n);

    printf("Max error: %f\n", compare(C,D,m,n));
}
