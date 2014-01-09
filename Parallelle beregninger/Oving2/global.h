#include <mpi.h>

// Global variables from main.c
extern int imageSize;
extern int rank, size,
    dims[2],
    coords[2],
    periods[2],
    north, south, east, west,
    local_height, local_width,
    width, height, border;

extern MPI_Comm cart_comm;

extern MPI_Datatype matrix_t,
					matrix_lpres_t,
					matrix_ldiverg_t,
					border_row_t,
					border_col_t,
					 
					matrix_t_resize,
					matrix_lpres_t_resize,
					matrix_ldiverg_t_resize,
					border_row_t_resize,
					border_col_t_resize;

extern float* local_pres;
extern float* local_pres0;
extern float* pres;
extern float* local_diverg;
extern float* diverg;
