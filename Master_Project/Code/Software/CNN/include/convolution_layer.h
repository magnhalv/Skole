typedef struct {
	int input_dim;
	int nof_inputs;
	int kernel_dim;
	int nof_kernels;
	int output_dim;
	int *connections;
} ClParameters;

void ClFeedforward(	double *in, double *W, double *B, double *out, ClParameters clp);