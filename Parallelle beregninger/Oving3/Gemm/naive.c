#include <complex.h>

void gemm(complex float* A,
        complex float* B,
        complex float* C,
        int m,
        int n,
        int k,
        complex float alpha,
        complex float beta){

    for(int x = 0; x < n; x++){
        for(int y = 0; y < m; y++){
            C[y*n + x] *= beta;
            for(int z = 0; z < k; z++){
                C[y*n + x] += alpha*A[y*k+z]*B[z*n + x];
            }
        }
    }
}
