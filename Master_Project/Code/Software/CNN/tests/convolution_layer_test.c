#include "../include/convolution_layer.h"
#include <stdio.h>
#include <math.h>

#define IMG_DIM 3
#define NOF_INPUTS 1
#define KERNEL_DIM 2
#define NOF_KERNELS 1
#define OUTPUT_DIM 2

int areEqual(double *array1, double *array2, int dim) {
	double epsilon = 0.000000001;
	for (int i = 0; i < dim; i++) {
		for (int j = 0; j < dim; j++) {
			if(fabs(array1[i*dim+j] - array2[i*dim+j]) > epsilon) {
				printf("%f - %f\n", array1[i*dim+j], array2[i*dim+j]);
				return 0;
			}
				
		}
	}	
}

int ClFeedforward_onlyOnes_onlyFours () {

	const int Img_Dim = 5;

	
	int connections[1] = {1};

	ClParameters clp;
	clp.input_dim = IMG_DIM;
	clp.nof_inputs = NOF_INPUTS;
	clp.kernel_dim = KERNEL_DIM;
	clp.nof_kernels = NOF_KERNELS;
	clp.output_dim = OUTPUT_DIM;
	clp.connections = connections;

	double input[IMG_DIM*IMG_DIM] = {1.0, 1.0, 1.0,
									1.0, 1.0, 1.0,
									1.0, 1.0, 1.0};
	double weights[KERNEL_DIM*KERNEL_DIM] = {1.0, 1.0,
											1.0, 1.0};
	double bias[NOF_KERNELS] = {1.0};

	double expected_result[OUTPUT_DIM*OUTPUT_DIM] = {4.0, 4.0, 4.0, 4.0};

	double output[per*per];


	ClFeedforward(input, weights, bias, output, clp);


	double epsilon = 0.000000001;
	for (int i = 0; i < OUTPUT_DIM; i++) {
		for (int j = 0; j < OUTPUT_DIM; j++) {
			if(fabs(output[i*OUTPUT_DIM+j] - expected_result[i*OUTPUT_DIM+j]) > epsilon) {
				printf("%f - %f\n", output[i*OUTPUT_DIM+j], expected_result[i*OUTPUT_DIM+j]);
				return 0;
			}
				
		}
	}

	return 1;
}

int main () {
	int result = ClFeedforward_onlyOnes_onlyFours();
	printf("%d\n", result);
	return 0;
}