#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Print the string in reverse.
// But only 10 chars max.
void reverse(char * string)
{
	// Make buffer
	char * mem = malloc(10);
	int i, lastChar;
	
	strcpy(mem, string);
	// Search for the first non null char
	for(i = 10; i >= 0; i--)
	{
		// Strings are terminated by null
		// Find first char
		if(mem[i] != 0)
		{
			lastChar = i;
			break;
		}
	}
	
	// Print starting with the last char.
	for(i = lastChar; i >= 0; i--)
		printf("%c", mem[i]);
	printf("\n");
	
	free(mem);
}

int main(int argc, char *argv[])
{
	int i;
	// Take all commandline arguments and print them in reverse.
	for(i = argc-1; i > 0; i--)
		reverse(argv[i]);
	return 0;
}
// The end
