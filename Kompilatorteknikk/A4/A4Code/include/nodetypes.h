#ifndef NODETYPES_H
#define NODETYPES_H

/*
 * Enumerated type for describing the various types of tree nodes.
 * Each node is labelled with one of these, to identify its nature
 * when traversing the syntax tree.
 */
typedef enum {
    PROGRAM, FUNCTION_LIST, STATEMENT_LIST, PRINT_LIST, EXPRESSION_LIST,
    VARIABLE_LIST, ARGUMENT_LIST, PARAMETER_LIST, DECLARATION_LIST,
    FUNCTION, STATEMENT, BLOCK, ASSIGNMENT_STATEMENT, RETURN_STATEMENT,
    PRINT_STATEMENT, NULL_STATEMENT, IF_STATEMENT, WHILE_STATEMENT, FOR_STATEMENT, PRINT_ITEM,
    EXPRESSION, DECLARATION, VARIABLE, INTEGER, TEXT
} nt_number;


/*
 * Structure for pairing integer and string encodings of node types.
 * Integers make readable code, strings make readable trees - this way, we
 * can pun freely back and forth between the two.
 */
typedef struct {
    nt_number index;
    char *text;
} nodetype_t;


/* Root node: program */
extern const nodetype_t program_n;

/* Node types for the lists */
extern const nodetype_t
    function_list_n, statement_list_n, print_list_n, expression_list_n,
    variable_list_n, argument_list_n, parameter_list_n, declaration_list_n;

/* Function declarations */
extern const nodetype_t function_n;

/* Statements and blocks */
extern const nodetype_t
    statement_n, block_n, assignment_statement_n, return_statement_n,
    print_statement_n, null_statement_n, if_statement_n, while_statement_n, for_statement_n;

/* Expressions and terminals */
extern const nodetype_t
    print_item_n, expression_n, declaration_n, variable_n, integer_n, text_n;

#endif
