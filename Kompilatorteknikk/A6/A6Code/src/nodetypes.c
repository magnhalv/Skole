#include <nodetypes.h>

/* Root node: program */
const nodetype_t
    program_n = { PROGRAM, "PROGRAM" };

/* Node types for the lists */
const nodetype_t
    function_list_n    = { .index=FUNCTION_LIST,    .text="FUNCTION_LIST" },
    statement_list_n   = { .index=STATEMENT_LIST,   .text="STATEMENT_LIST" },
    print_list_n       = { .index=PRINT_LIST,       .text="PRINT_LIST" },
    expression_list_n  = { .index=EXPRESSION_LIST,  .text="EXPRESSION_LIST" },
    variable_list_n    = { .index=VARIABLE_LIST,    .text="VARIABLE_LIST" },
    argument_list_n    = { .index=ARGUMENT_LIST,    .text="ARGUMENT_LIST" },
    parameter_list_n   = { .index=PARAMETER_LIST,   .text="PARAMETER_LIST" },
    declaration_list_n = { .index=DECLARATION_LIST, .text="DECLARATION_LIST"};

/* Function declarations */
const nodetype_t function_n = { .index=FUNCTION, .text="FUNCTION" };

/* Statements and blocks */
const nodetype_t
    assignment_statement_n = {
        .index=ASSIGNMENT_STATEMENT, .text="ASSIGNMENT_STATEMENT"
    },
    statement_n        = { .index=STATEMENT,        .text="STATEMENT" },
    block_n            = { .index=BLOCK,            .text="BLOCK" },
    return_statement_n = { .index=RETURN_STATEMENT, .text="RETURN_STATEMENT" },
    print_statement_n  = { .index=PRINT_STATEMENT,  .text="PRINT_STATEMENT" },
    null_statement_n   = { .index=NULL_STATEMENT,   .text="NULL_STATEMENT" },
    if_statement_n     = { .index=IF_STATEMENT,     .text="IF_STATEMENT" },
    while_statement_n  = { .index=WHILE_STATEMENT,  .text="WHILE_STATEMENT" },
    for_statement_n  = { .index=FOR_STATEMENT,  .text="FOR_STATEMENT" };

/* Expressions and terminals */
const nodetype_t
    print_item_n  = { .index=PRINT_ITEM,  .text="PRINT_ITEM" },
    expression_n  = { .index=EXPRESSION,  .text="EXPRESSION" },
    declaration_n = { .index=DECLARATION, .text="DECLARATION" },
    variable_n    = { .index=VARIABLE,    .text="VARIABLE" },
    integer_n     = { .index=INTEGER,     .text="INTEGER" },
    text_n        = { .index=TEXT,        .text="TEXT" };
