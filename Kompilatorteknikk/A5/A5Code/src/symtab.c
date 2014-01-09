#include "symtab.h"


static hash_t **scopes;
static symbol_t **values;
static char **strings;
static int32_t scopes_size = 16, scopes_index = -1;
static int32_t values_size = 16, values_index = -1;
static int32_t strings_size = 16, strings_index = -1;


void
symtab_init ( void )
{
    /* String table */
    strings = malloc ( strings_size * sizeof(char *) );

    /* Stack of scopes */
    scopes = (hash_t **) calloc ( scopes_size, sizeof (hash_t *) );
    values = (symbol_t **) calloc ( values_size, sizeof (symbol_t *) );
    scope_add ();
}


void
symtab_finalize ( void )
{
    /* String table */
    for ( int32_t i=strings_index; i>=0; i-- )
        free ( strings[i] );
    free ( strings );

    /* Stack of scopes */
    while ( scopes_index > -1 )
        scope_remove ();
    while ( values_index >= 0 )
    {
        free ( values[values_index]->label );
        free ( values[values_index] );
        values_index -= 1;
    }
    free ( scopes );
    free ( values );
}


int32_t
strings_add ( char *str )
{
    strings_index += 1;
    strings[strings_index] = str;
    if ( strings_index == strings_size )
    {
        strings_size *= 2;
        strings = realloc ( strings, strings_size * sizeof(char *) );
    }
    return strings_index;
}


void
strings_output ( FILE *stream )
{
    fputs (
        ".data\n"
        ".INTEGER: .string \"%d \"\n",
        stream
    );
    for ( int i=0; i<=strings_index; i++ )
        fprintf ( stream, ".STRING%d: .string %s\n", i, strings[i] );
    fputs ( ".globl main\n", stream );
}


void
scope_add ( void )
{
    scopes_index += 1;
    if ( scopes_index == scopes_size )
    {
        scopes_size *= 2;
        scopes = realloc ( scopes, scopes_size * sizeof (hash_t *) );
    }
    scopes[scopes_index] = ght_create ( HASH_BUCKETS );
}


void
scope_remove ( void )
{
    ght_finalize ( scopes[scopes_index] );
    scopes_index -= 1;
}


void
symbol_insert ( char *key, symbol_t *value )
{
#ifdef DUMP_SYMTAB
fprintf ( stderr, "Inserting (%s,%d)\n", key, value->stack_offset );
#endif

    value->depth = scopes_index;

    ght_insert ( scopes[scopes_index], value, strlen(key)+1, key );
    values_index += 1;
    if ( values_index == values_size )
    {
        values_size *= 2;
        values = realloc ( values, values_size * sizeof(symbol_t *) );
    }
    values[values_index] = value;
}


symbol_t *
symbol_get ( char *key )
{
    int32_t d = scopes_index;
    symbol_t *result = NULL;
    while ( result == NULL && d > -1 )
    {
        result = (symbol_t *) ght_get ( scopes[d], strlen(key)+1, key );
        d -= 1;
    }
#ifdef DUMP_SYMTAB
    if ( result != NULL )
        fprintf ( stderr, "Retrieving (%s,%d)\n", key, result->stack_offset );
#endif
    return result;
}
