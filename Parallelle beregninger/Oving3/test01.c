#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[])
{
	char *mem = malloc(100);
	mem = "Hello\n";
	printf("%s", mem);
	return 0;
}
