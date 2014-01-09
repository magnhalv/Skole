#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[])
{
	char *mem = malloc(128);
	int i;
	for(i = 0; i < 32; i++) {
		mem[i] = 300;
		mem[i+64] = 300;	
	}
	free(mem);
	return 0;
}
