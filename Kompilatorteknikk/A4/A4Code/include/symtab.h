#ifndef SYMTAB_H
#define SYMTAB_H


#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include "ght_hash_table.h"

#define HASH_BUCKETS 8
typedef ght_hash_table_t hash_t;

typedef struct {
    int32_t stack_offset, depth;
    char *label;
} symbol_t;


void symtab_init ( void );
void symtab_finalize ( void );

int32_t strings_add ( char *str );
void strings_output ( FILE *stream );

void scope_add ( void );
void scope_remove ( void );

void symbol_insert ( char *key, symbol_t *value );
symbol_t *symbol_get ( char *key );


#endif
