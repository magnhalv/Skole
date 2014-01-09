#include <stdio.h>
#include <stdlib.h>
#include <cuda.h>

//#include "bmp.h"
extern "C" void write_bmp(unsigned char* data, int width, int height);
extern "C" unsigned char* read_bmp(char* filename);
//#include "host_blur.h"
extern "C" void host_blur(unsigned char* inputImage, unsigned char* outputImage, int size);

const int DIM_X = 512;
const int DIM_Y = 512;

void print_properties(){
	int deviceCount = 0;
  cudaGetDeviceCount(&deviceCount);
  printf("Device count: %d\n", deviceCount);

	cudaDeviceProp p;
	cudaSetDevice(0);
	cudaGetDeviceProperties (&p, 0);
	printf("Compute capability: %d.%d\n", p.major, p.minor);
	printf("Name: %s\n" , p.name);
	printf("\n\n");
}

__global__ void device_blur(unsigned char *A, unsigned char *B) {
    int t_id = threadIdx.x;
    int b_id = blockIdx.x;

    //Shared array containing the pixels in this row, and the ones below and above. 
    __shared__ unsigned char As[3][DIM_X]; 
     

    //Make all the threads load values into the shared memory.
    //Except if you're on the border.  
    if (b_id != 0) As[0][t_id] = A[(b_id-1)*DIM_X + t_id];
    if (b_id != DIM_Y-1) As[2][t_id] = A[(b_id+1)*DIM_X + t_id];
    As[1][t_id] = A[(b_id)*DIM_X + t_id]; 
    //Wait until all the threads are done.
    __syncthreads();

    //Calculate pixel
    unsigned char new_pixel;
    if ((b_id != 0 && b_id != DIM_Y-1) && (t_id != 0 && t_id != DIM_X-1)){
        new_pixel = 0;
        for (int i = 2; i >= 0; i--) {
            for (int j = -1; j < 2; j++) {
                new_pixel += (As[i][t_id+j])/9.0;
            }
        }
    }
    else new_pixel = As[1][t_id];
    //Store in global. 
    B[b_id*DIM_X + t_id] = new_pixel; 
    
}


int main(int argc,char **argv) {
	
    // Prints some device properties, also to make sure the GPU works etc.
    print_properties();

    unsigned char* picture = read_bmp("peppers.bmp");
    unsigned char *A, *B, *C;

    size_t size = sizeof(unsigned char)*DIM_X*DIM_Y;
    //Currently we do the bluring on the CPU
    //host_blur(A, B, 512);
	
    // You need to:

    // 1. Allocate buffers for the input image and the output image
    cudaMalloc((void**)&B, size);
    cudaMalloc((void**)&A, size);
    // 2. Transfer the input image from the host to the device
    cudaMemcpy(A, picture, size, cudaMemcpyHostToDevice);
    // 3. Launch the kernel which does the bluring
	device_blur<<<DIM_Y, DIM_X>>>(A, B);
    C = (unsigned char*)malloc(size);
    // 4. Transfer the result back to the host.
    cudaMemcpy(C, B, size, cudaMemcpyDeviceToHost);
    write_bmp(C, 512, 512);
    cudaFree(A);
    cudaFree(B);
    free(picture);
    free(C);


	return 0;
}
