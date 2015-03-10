JPGS=$(shell ls *.dat | sed s/\.dat/.jpg/)

all: kmeans kmeans_cuda kmeans_cuda_old

speed:
	scp * magnhalv@gpu04.idi.ntnu.no:~/Oving5/kmeans
	ssh magnhalv@gpu04.idi.ntnu.no 'cd Oving5/kmeans/;make all;time ./kmeans 4096 8192;time ./kmeans_cuda 4096 8192'
	scp magnhalv@gpu04.idi.ntnu.no:~/Oving5/kmeans/0000.dat ../kmeans
	scp magnhalv@gpu04.idi.ntnu.no:~/Oving5/kmeans/0001.dat ../kmeans

send: 
	scp * magnhalv@gpu04.idi.ntnu.no:~/Oving5/kmeans
	ssh magnhalv@gpu04.idi.ntnu.no 'cd Oving5/kmeans/;make all;time ./kmeans_cuda 1024 2048;time ./kmeans 1024 2048'
	scp magnhalv@gpu04.idi.ntnu.no:~/Oving5/kmeans/0000.dat ../kmeans
	scp magnhalv@gpu04.idi.ntnu.no:~/Oving5/kmeans/0001.dat ../kmeans


kmeans: kmeans.c
	gcc -std=c99 -O3 -o kmeans kmeans.c -lm
	
kmeans_cuda: kmeans_cuda.cu
	nvcc -arch=sm_20 -O3 -o kmeans_cuda kmeans_cuda.cu -lcudart -lm

kmeans_cuda_old: kmeans_cuda_old.cu
	nvcc -arch=sm_20 -O3 -o kmeans_cuda_old kmeans_cuda_old.cu -lcudart -lm


plot: plot.txt
	gnuplot gpbatch.txt
	
plot.txt: kmeans
	./kmeans 10 300 > plot.txt
	
	
jpgs: ${JPGS}

%.jpg: %.dat
	gnuplot -e "infile='$*.dat'; outfile='$*.jpg'" gpbatch.txt
	-rm -f $*.dat
	
clean:
	-rm -f kmeans kmeans_cuda plot.txt plot.jpg
