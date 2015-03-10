#include <stdio.h>
#include <stdlib.h>
#include <math.h>

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

int main (){
	float out[5] = {1.0, 1.0, 1.0, 1.0, 1.0};
	float a[5] = {1.0,1.0,1.0,1.0,1.0};
	float b[5] = {1.0,1.0,1.0,1.0,1.0};

	float s = sumadd(out, a, b, 5);
	printf("%f\n", s);
	return 0;
}