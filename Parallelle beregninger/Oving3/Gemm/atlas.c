#include <complex.h>
#include <cblas.h>

void gemm(complex float * A,
        complex float* B,
        complex float* C,
        int m,
        int n,
        int k,
        complex float alpha,
        complex float beta){

    cblas_cgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, m, n, k, (void*)&alpha, A, k, B, n, (void*)&beta, C, n);
}
