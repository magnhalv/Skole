#include <stdio.h>
#include <stdlib.h>

int main () {
	int table[2][2] = {{1, 2}, {3, 4}};
	printf("%d\n", *(table[0]+3));
	return 0;
}