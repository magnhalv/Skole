all: gemm gemm_openmp gemm_pthread

gemm: gemm.c
	gcc -std=c99 -O3 -o gemm gemm.c -lm
	
gemm_openmp: gemm_openmp.c
	gcc -std=c99 -O3 -o gemm_openmp gemm_openmp.c -lm -fopenmp

gemm_pthread: gemm_pthread.c
	gcc -std=c99 -O3 -o gemm_pthread gemm_pthread.c -lm -lpthread
	
clean:
	-rm -f gemm gemm_pthread gemm_openmp

test: test_openmp.c
	gcc -std=c99 -O3 -o test_openmp test_openmp.c -lm -fopenmp