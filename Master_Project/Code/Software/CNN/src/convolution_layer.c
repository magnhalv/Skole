#include "../include/convolution_layer.h"
#include <stdio.h>

static int in_dim, nof_inputs;
static int kernel_dim, nof_kernels;
static int output_dim;
static int *connections;

void SetGlobalVariables (ClParameters clp) {
	in_dim = clp.input_dim;
	nof_inputs = clp.nof_inputs;
	kernel_dim = clp.kernel_dim;
	nof_kernels = clp.nof_kernels;
	output_dim = clp.output_dim;
	connections = clp.connections;
} 

void Convolution(double *in, double *W, double *out, int output_nr, double bias) {
	for (int input = 0; input < nof_inputs; input++) {
		for (int y = 0; y < output_dim; y++) {
			for (int x = 0; x < output_dim; x++) {
				double sum = 0;
				for (int dy = 0; dy < kernel_dim; dy++) {
					for (int dx = 0; dx < kernel_dim; dx++) {
						sum += W[output_nr*kernel_dim*kernel_dim+dy*kernel_dim+dx]*
							in[input*in_dim*in_dim+y*in_dim+x];
					}
				}
				out[y*output_dim+x] = sum;
			}
		}	
	}
	
}

void ClFeedforward(double *in, double *W, double *B, double *out, ClParameters clp) {
	
	SetGlobalVariables(clp);

	for (int output = 0; output < nof_kernels; output++) {
		Convolution(in, W, out, output, 5);
	}
}