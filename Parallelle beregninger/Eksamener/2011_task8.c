#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>
#include <time.h>
#include <cuda.h>

int main (int argc, char **argv) {

	int size;
	int rank;
	int nofTosses = atoi(argv[1]);
	int send_val;
	int number_in_circle;

	srand(time(NULL));
	MPI_Init(&argc, &argv);
	MPI_Comm_size(MPI_COMM_WORLD, &size);
	MPI_Comm_rank(MPI_COMM_WORLD, &rank);

	long long int x = ((float)rand()/(float)RAND_MAX);
	long long int y = ((float)rand()/(float)RAND_MAX);

	long long int distance_squared = x*x + y*y;
	
	if (distance_squared <= 1) send_val = 1;
	else send_val = 0; 


	MPI_Reduce(&send_val, &number_in_circle, 1, MPI_INT, MPI_SUM, 0, MPI_COMM_WORLD);
	if (rank == 0) 
		double pi_estimate = 4*number_in_circle/(double)number_in_circle);
	
}

void task8_b () {

	char big_grid[500][500];
	char local_grid[250][250];


	MPI_Datatype sub_grid, sub_grid_resized;
	MPI_Type_vector(250, 250, 500, MPI_CHAR, &sub_grid_resized);
	MPI_Type_create_resized(sub_grid_resized, 0, sizeof(char), &sub_grid);
	MPI_Type_commit(&sub_grid);

	MPI_Datatype rcv_sub_grid, rcv_sub_grid_resized;
	MPI_Type_vector(250, 250, 250, MPI_CHAR, &rcv_sub_grid_resized);
	MPI_Type_create_resized(rcv_sub_grid_resized, 0, sizeof(char), &rcv_sub_grid);
	MPI_Type_commit(&rcv_sub_grid);

	if (rank == 0) {
		MPI_Send(big_grid, 1, sub_grid, 1, 0, MPI_COMM_WORLD);
	}
	else if (rank == 1) {
		MPI_Receive(local_grid, 1, rcv_sub_grid, 0, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
	}




}

__global__ void sum_add(float *out, float *a, float *b, int n) {

	int global_id = gridDim.x*blockId + threadIdx.x;
	int local_id = threadIdx.x;
	__Shared__float reduction_sum[blockDim.x];

	reduction_sum[local_id] = a[global_id] + b[global_id];

	for unsigned int stride = 1; stride < blockDim.x; stride *= 2){
		__synchthreads();
		  if (t % (2*stride) == 0)
			reduction_sum[t] += reduction_sum[t+stride]
  	}

  	if (local_id == 0)
  		out[global_id] = reduction_sum[0];
	
}

float sumadd(float *out, float *a, float *b, int n) { 
	float s = 0.0f; 
	int i;
	#pragma omp parallel for reduction(+:s) 
	for(i=0;i<n;++i) {
		out[i]=a[i] + b[i]; 
		s += out[i];
	} 
    return s;
}

 
__global__ reduction () {

	__Shared__ float reduction_sum[blockDim.x];
	unsigned int t_id = threadIdx;

	for (unsigned int s = blockDim.x/2; s >>= 1) {
		__synchthreads();
		if (t_id < s) ) {
			reduction_sum[t_id] += reduction_sum[t_id + s];
		}	
	} 
}