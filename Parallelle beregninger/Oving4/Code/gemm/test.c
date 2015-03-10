#include <stdio.h>
#include <stdlib.h>
#include <math.h>

int main (int argc, char ** argv) {

	float *lol = malloc(sizeof(float)*10);
	for (int i = 0; i < 10; i++)
		lol[i] = i;
	float *per = &lol[5];
	for (int i = 0; i < 5; i++) {
		printf("%f\n", per[i]);
	}
	free(lol);
	return 0;

}