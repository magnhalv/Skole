JPGS=$(shell ls *.dat | sed s/\.dat/.jpg/)

all: kmeans kmeans_openmp kmeans_pthread

kmeans: kmeans.c
	gcc -std=c99 -O3 -o kmeans kmeans.c -lm
	
kmeans_openmp: kmeans_openmp.c
	gcc -std=c99 -O3 -o kmeans_openmp kmeans_openmp.c -lm -fopenmp

kmeans_pthread: kmeans_pthread.c
	gcc -std=c99 -O3 -o kmeans_pthread kmeans_pthread.c -lm -lpthread

plot: plot.txt
	gnuplot -e "infile='plot.txt'; outfile='plot.jpg'" gpbatch.txt
	
plot.txt: kmeans
	./kmeans 1 10 300 > plot.txt
	
	
jpgs: ${JPGS}

%.jpg: %.dat
	gnuplot -e "infile='$*.dat'; outfile='$*.jpg'" gpbatch.txt
	-rm -f $*.dat
	
clean:
	-rm -f kmeans plot.txt plot.jpg
