#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>
#include "global.h"

// Indexing macro for local pres and local divergs arrays
#define LP(row,col) ((row)+border)*(local_width + 2*border) + ((col) + border)
#define LD(row,col) (row*local_width) + col


// Distribute the diverg (bs) from rank 0 to all the processes
void distribute_diverg_and_pres(){ 
	//Number of elements to send to each process. Will be set to 1 for each process. 
	int *send_counts = (int*)malloc(sizeof(int)*size);
	//The displacement for where each matrix_t should start. 
	int *displs = (int*)malloc(sizeof(int)*size);
	int count = 0;
	for (int i = 0; i < dims[0]; i++) {
		for (int j = 0; j < dims[1]; j++) {
			send_counts[i*dims[1] + j] = 1;
			displs[i*dims[1] + j] = i*local_height*(local_width*dims[1]+2*border) + j*local_width;
		}
	}
	//Scatter the diverg matrix among the processes. 
	MPI_Scatterv(&diverg[local_width*dims[1]+border*3], send_counts, displs, matrix_t, local_diverg, 1,
					matrix_ldiverg_t , 0, cart_comm);
	//Scatter the pres matrix among the processes. 
	MPI_Scatterv(&pres[local_width*dims[1]+border*3], send_counts, displs, matrix_t, &local_pres0[LP(0,0)], 
					1, matrix_lpres_t, 0, cart_comm);
	 
	free(send_counts);
	free(displs);
}

// Gather the results of the computation at rank 0
void gather_pres(){

	int *recv_counts = (int*)malloc(sizeof(int)*size);
	int *displs = (int*)malloc(sizeof(int)*size);
	for (int i = 0; i < dims[0]; i++) {
		for (int j = 0; j < dims[1]; j++) {
			recv_counts[i*dims[1] + j] = 1;
			displs[i*dims[1] + j] = i*(local_width*dims[1]+border*2)*local_height + j*local_width;
		}
	}
	MPI_Gatherv(&local_pres[LP(0,0)], 1,  matrix_lpres_t, 
                &pres[local_width*dims[1]+3*border], recv_counts, displs, matrix_t, 0, cart_comm);
	free(recv_counts);
	free(displs);
}

// Exchange borders between processes during computation
/*
	- All nodes with a process to the north sends their northern border. 
	- The processes with no northern neighbour call a recv, which matches their southern process' send.
	- The top processes will then send their southern border, thus matching their southern process' recv.
	- This will propagate all the way down to the most southern processes.
	- All processes will thus exchange their southern and northern border. 
	- Same principle goes for west and east. 
	- If a process is on an edge, it will simply copy its own border into the halo. 
*/
void exchange_borders(){

	
	MPI_Status status_n, status_s, status_e, status_w;
	
	if (north >= 0) {
		MPI_Send(&local_pres0[LP(0,0)], 1, border_row_t, north, 0, cart_comm);
		MPI_Recv(&local_pres0[LP(-1, 0)], 1, border_row_t, north, 0, cart_comm, &status_n);
	}
	//If no neighbour, copy own border into the halo. 
	else {
		for (int i = 0; i < local_width; i++) {
			local_pres0[LP(-1, i)] = local_pres0[LP(0, i)];
		}
	} 
	if (south >= 0) {
		MPI_Recv(&local_pres0[LP(local_height, 0)], 1, border_row_t, south, 0, cart_comm, &status_s);
		MPI_Send(&local_pres0[LP(local_height-1, 0)], 1, border_row_t, south, 0, cart_comm);
	}
	else {
		for (int i = 0; i < local_width; i++) {
			local_pres0[LP(local_height, i)] = local_pres0[LP(local_height-1, i)];
		}
	}
	
	if (west >= 0) {
		MPI_Recv(&local_pres0[LP(0, -1)], 1, border_col_t, west, 0, cart_comm, &status_w);
		MPI_Send(&local_pres0[LP(0, 0)], 1, border_col_t, west, 0, cart_comm);
	}
	else {
		for (int i = 0; i < local_height; i++) {
			local_pres0[LP(i, -1)] = local_pres0[LP(i, 0)];
		}
	}
	
	if (east >= 0) {
		MPI_Send(&local_pres0[LP(0, local_width-1)], 1, border_col_t, east, 0, cart_comm);
		MPI_Recv(&local_pres0[LP(0, local_width)], 1, border_col_t, east, 0, cart_comm, &status_e);
	}
	else {
		for (int i = 0; i < local_height; i++) {
			local_pres0[LP(i, local_width)] = local_pres0[LP(i, local_width-1)];
		}
	}
}

// One jacobi iteration
void jacobi_iteration(){
	int i, j;
	//Do the calculation
	for (i = 0; i < local_height; i++) {
		for (j = 0; j < local_width; j++) {
			local_pres[LP(i, j)] = 0.25*(local_pres0[LP(i+1,j)] + local_pres0[LP(i-1,j)] + 
			local_pres0[LP(i,j+1)] + local_pres0[LP(i,j-1)] - local_diverg[LD(i, j)]);
		}
	}	
	//Copy the values in local_pres0 to local_pres. 
	for (i = 0; i < local_height; i++) {
		for (j = 0; j < local_width; j++) {
			local_pres0[LP(i, j)] = local_pres[LP(i,j)];
		}
	}
	
}

// Solve linear system with jacobi method
void jacobi (int iter) {
	
	//Distribute the diverg and pres matrix among the processes. 
	distribute_diverg_and_pres();
	
	//Exchange borders and preform calculation for each iteration.
    for (int k=0; k<iter; k++) {
		exchange_borders();
		jacobi_iteration();
    }
	//Gather the result. 
	gather_pres();

}
