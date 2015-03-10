#include "symtab.h"
#include <string.h>

// static does not mean the same as in Java.
// For global variables, it means they are only visible in this file.

// Pointer to stack of hash tables 
static hash_t **scopes;

// Pointer to array of values, to make it easier to free them
static symbol_t **values;

// Pointer to array of strings, should be able to dynamically expand as new strings
// are added.
static char **strings;

// Helper variables for manageing the stacks/arrays
static int32_t scopes_size = 16, scopes_index = -1;
static int32_t values_size = 16, values_index = -1;
static int32_t strings_size = 16, strings_index = -1;


void
symtab_init ( void )
{
	scopes = (hash_t**)malloc(sizeof(hash_t*)*scopes_size);
	values = (symbol_t**)malloc(sizeof(symbol_t*)*values_size);
	strings = (char**)malloc(sizeof(char*)*strings_size);
}


void
symtab_finalize ( void )
{
	free(scopes);
	free(values);
	free(strings);
}


int strings_add ( char *str )
{
	strings_index++;
	//Expands the array if it's full.
	if (strings_index == strings_size) {
		strings_size = strings_size*2;
		strings = (char**)realloc(strings, sizeof(char*)*strings_size);	
	}	
	strings[strings_index] = str;
	return strings_index;
}


void
strings_output ( FILE *stream ) {
	
	fprintf(stream, ".data\n");	
	fprintf(stream, ".INTEGER: .string \"%%d \"\n");
	
	for (int i = 0; i <= (strings_index); i++) {
		fprintf(stream,".STRING");
		fprintf(stream, "%d", i);
		fprintf(stream, ": .string ");
		fprintf(stream, "%s", strings[i]);
		fprintf(stream, "\n");
	} 
	fprintf(stream, ".globl main\n");
}


void
scope_add ( void )
{
	scopes_index++;
	if (scopes_index == scopes_size) {
		scopes_size = scopes_size*2;
		scopes = (hash_t**)realloc(scopes, sizeof(hash_t*)*scopes_size);
	}
	hash_t *newScope;
	newScope = ght_create(HASH_BUCKETS);
	scopes[scopes_index] = newScope;
	
}


void
scope_remove ( void )
{
	ght_finalize(scopes[scopes_index]);
	scopes_index--;
	if (scopes_index*2 == scopes_size) {
		scopes_size = scopes_size/2;
		scopes = (hash_t**)realloc(scopes, sizeof(hash_t*)*scopes_size);	
	}
}


void
symbol_insert ( char *key, symbol_t *value )
{
	
	int keyLength = strlen(key);
	value->depth = scopes_index;
	ght_insert(scopes[scopes_index], value, keyLength, key);
	
	//Adds the value to the values array, for easily freeing up memory later. 
	values_index++;
	if (values_index == values_size) {
		values_size = values_size*2;
		values = (symbol_t**)realloc(values, sizeof(symbol_t*)*values_size);
	}
	values[values_index] = value;

	// Keep this for debugging/testing
	#ifdef DUMP_SYMTAB
	fprintf ( stderr, "Inserting (%s,%d)\n", key, value->stack_offset );
	#endif
}


symbol_t *
symbol_get ( char *key )
{
	int keyLength = strlen(key);
	symbol_t *result;
	//Checks the deepest scope, then continues outward until it finds the symbol.
	for (int i = scopes_index; i >= 0; i--) {
		result = ght_get(scopes[i], keyLength, key);
		if (result != NULL) break;	
	}	

// Keep this for debugging/testing
#ifdef DUMP_SYMTAB
    if ( result != NULL )
        fprintf ( stderr, "Retrieving (%s,%d)\n", key, result->stack_offset );
#endif
	return result;
}
