CFLAGS += -std=c99

all : blur_cuda

send: 
	scp blur_cuda.cu magnhalv@gpu04.idi.ntnu.no:~/
	ssh magnhalv@gpu04.idi.ntnu.no 'make all'

blur_cuda: bmp.o host_blur.o blur_cuda.cu
	nvcc -arch=sm_20  host_blur.o bmp.o blur_cuda.cu -o blur_cuda -lcudart
	'./blur_cuda'

clean:
	rm *.o blur_cuda
