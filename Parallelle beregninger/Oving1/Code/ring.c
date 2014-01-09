#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char** argv){
	int size, rank, in;
	MPI_Status status;
	MPI_Init(&argc,&argv);
	MPI_Comm_size(MPI_COMM_WORLD, &size);
	MPI_Comm_rank(MPI_COMM_WORLD, &rank);
	if(rank == 0){
			MPI_Send(&rank, 1, MPI_INT, rank+1, 1, MPI_COMM_WORLD);
			MPI_Recv(&in, 1, MPI_INT, size-1, 1, MPI_COMM_WORLD, &status);
			printf("Rank %d recieved %d\n",rank, in);
	}
	else{
		int value, target;
		MPI_Recv(&in, 1, MPI_INT, rank-1, 1, MPI_COMM_WORLD, &status);
		printf("Rank %d recieved %d\n",rank, in);
		
		value = in + rank;
		if (rank == size-1) target = 0;
		else target = rank+1;
		MPI_Send(&value, 1, MPI_INT, target, 1, MPI_COMM_WORLD);
		
	}
	MPI_Finalize();
}
