%{
#include "nodetypes.h"
#include "tree.h"
#include <stdlib.h>

/* This defines the type for every $$ value in the productions. */
#define YYSTYPE node_t *


/*
 * Convenience macros for repeated code. These macros are named CN for "create
 * node", number of children (3 is the most we need for a basic VSL syntax
 * tree), and with a trailing N or D for the data label (N is "NULL", D means
 * something goes in the data pointer).
 */
#define CN0D(type,data)\
    node_init ( (node_t*) malloc(sizeof(node_t)), type, data, 0 )
#define CN0N(type)\
    node_init ( (node_t*)malloc(sizeof(node_t)), type, NULL, 0 )
#define CN1D(type,data,A) \
    node_init ( (node_t*)malloc(sizeof(node_t)), type, data, 1, A )
#define CN1N(type,A) \
    node_init ( (node_t*)malloc(sizeof(node_t)), type, NULL, 1, A )
#define CN2D(type,data,A,B) \
    node_init ( (node_t*)malloc(sizeof(node_t)), type, data, 2, A, B )
#define CN2N(type,A,B) \
    node_init ( (node_t*)malloc(sizeof(node_t)), type, NULL, 2, A, B )
#define CN3N(type,A,B,C) \
    node_init ( (node_t*)malloc(sizeof(node_t)), type, NULL, 3, A, B, C )


/*
 * Variables connecting the parser to the state of the scanner - defs. will be
 * generated as part of the scanner (lexical analyzer).
 */
extern char yytext[];
extern int yylineno;


/*
 * Since the return value of yyparse is an integer (as defined by yacc/bison),
 * we need the top level production to finalize parsing by setting the root
 * node of the entire syntax tree inside its semantic rule instead. This global
 * variable will let us get a hold of the tree root after it has been
 * generated.
 */
node_t *root;


/*
 * These functions are referenced by the generated parser before their
 * definition. Prototyping them saves us a couple of warnings during build.
 */
int yyerror ( const char *error );  /* Defined below */
int yylex ( void );                 /* Defined in the generated scanner */
%}


/* Tokens for all the key words in VSL */
%token NUMBER STRING IDENTIFIER ASSIGN FUNC PRINT RETURN CONTINUE
%token IF THEN ELSE FI WHILE DO DONE VAR FOR TO 
%token EQUAL GEQUAL LEQUAL NEQUAL


/*
 * Operator precedences: 
 * + and - bind to the left { a+b+c = (a+b)+c }
 * * and / bind left like + and -, but has higher precedence
 * Unary minus has only one operand (and thus no direction), but highest
 * precedence. Since we've already used '-' for the binary minus, unary minus
 * needs a ref. name and explicit setting of precedence in its grammar
 * production.
 */
%left EQUAL NEQUAL
%left GEQUAL LEQUAL '<' '>'
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS


/*
 * The grammar productions follow below. These are mostly a straightforward
 * statement of the language grammar, with semantic rules building a tree data
 * structure which we can traverse in subsequent phases in order to understand
 * the parsed program. (The leaf nodes at the bottom need somewhat more
 * specific rules, but these should be manageable.)
 * A lot of the work to be done later could be handled here instead (reducing
 * the number of passes over the syntax tree), but sticking to a parser which
 * only generates a tree makes it easier to rule it out as an error source in
 * later debugging.
 */ 

%%
program: function_list {
    root = node_init ( (node_t*)malloc(sizeof(node_t)), program_n, NULL, 1, $1);
};
function_list: function      { $$ = CN1N ( function_list_n, $1 ); }
    | function_list function { $$ = CN2N ( function_list_n, $1, $2 ); }
    ;
statement_list: statement       { $$ = CN1N ( statement_list_n, $1 ); }
    | statement_list statement  { $$ = CN2N ( statement_list_n, $1, $2 ); }
    ;
print_list: print_item          { $$ = CN1N ( print_list_n, $1 ); }
    | print_list ',' print_item { $$ = CN2N ( print_list_n, $1, $3 ); }
    ;
expression_list: expression          { $$ = CN1N ( expression_list_n, $1 ); }
    | expression_list ',' expression { $$ = CN2N (expression_list_n, $1, $3); }
    ;
variable_list: variable          { $$ = CN1N ( variable_list_n, $1 ); }
    | variable_list ',' variable { $$ = CN2N ( variable_list_n, $1, $3 ); }
    ;
argument_list: expression_list  { $$ = CN1N ( argument_list_n, $1 ); }
    | /* e */                   { $$ = NULL; }
    ;
parameter_list:
      variable_list { $$ = CN1N ( parameter_list_n, $1 ); }
    | /* e */       { $$ = NULL; }
    ;
declaration_list:
      declaration_list declaration  { $$ = CN2N(declaration_list_n, $1, $2); }
    | /* e */                       { $$ = NULL; }
    ;
function:
      FUNC variable '(' parameter_list ')' statement
        { $$ = CN3N ( function_n, $2, $4, $6 ); }
    ;
statement:
      assignment_statement { $$ = CN1N ( statement_n, $1 ); }
    | return_statement     { $$ = CN1N ( statement_n, $1 ); }
    | print_statement      { $$ = CN1N ( statement_n, $1 ); }
    | null_statement       { $$ = CN1N ( statement_n, $1 ); }
    | if_statement         { $$ = CN1N ( statement_n, $1 ); }
    | while_statement      { $$ = CN1N ( statement_n, $1 ); }
    | for_statement        { $$ = CN1N ( statement_n, $1 ); }
    | block                { $$ = CN1N ( statement_n, $1 ); }
    ;
block: '{' declaration_list statement_list '}' { $$ = CN2N(block_n, $2, $3); };
assignment_statement:
      variable ASSIGN expression { $$ = CN2N(assignment_statement_n, $1, $3); }
    ;
return_statement: RETURN expression { $$ = CN1N ( return_statement_n, $2 ); };
print_statement:  PRINT print_list { $$ = CN1N ( print_statement_n, $2 ); };
null_statement:   CONTINUE { $$ = CN0N ( null_statement_n ); };
if_statement:
      IF expression THEN statement FI
        { $$ = CN2N (if_statement_n, $2, $4); }
    | IF expression THEN statement ELSE statement FI
        { $$ = CN3N ( if_statement_n, $2, $4, $6 ); }
    ;
while_statement:
      WHILE expression DO statement DONE
        { $$ = CN2N ( while_statement_n, $2, $4 ); }
    ;
for_statement:
             FOR assignment_statement TO expression DO statement DONE
             { $$ = CN3N ( for_statement_n, $2, $4, $6); }
             ;
print_item:
      expression { $$ = CN1N ( print_item_n, $1 ); }
    | text       { $$ = CN1N ( print_item_n, $1 ); }
    ;
expression:
      expression '+' expression { $$ = CN2D(expression_n, STRDUP("+"),$1,$3 ); }
    | expression '-' expression { $$ = CN2D(expression_n, STRDUP("-"),$1,$3 ); }
    | expression '*' expression { $$ = CN2D(expression_n, STRDUP("*"),$1,$3 ); }
    | expression '/' expression { $$ = CN2D(expression_n, STRDUP("/"),$1,$3 ); }
    | expression '>' expression { $$ = CN2D(expression_n, STRDUP(">"),$1,$3 ); }
    | expression '<' expression { $$ = CN2D(expression_n, STRDUP("<"),$1,$3 ); }
    | expression EQUAL expression  { $$ = CN2D(expression_n, STRDUP("=="),$1,$3 ); }
    | expression NEQUAL expression { $$ = CN2D(expression_n, STRDUP("!="),$1,$3 ); }
    | expression GEQUAL expression { $$ = CN2D(expression_n, STRDUP(">="),$1,$3 ); }
    | expression LEQUAL expression { $$ = CN2D(expression_n, STRDUP("<="),$1,$3 ); }
    | '-' expression %prec UMINUS { $$ = CN1D(expression_n, STRDUP("-"), $2); }
    | '(' expression ')'          { $$ = CN1N ( expression_n, $2 ); }
    | integer                     { $$ = CN1N ( expression_n, $1 ); }
    | variable                    { $$ = CN1N ( expression_n, $1 ); }
    | variable '(' argument_list ')' { $$ = CN2D ( expression_n, STRDUP("F"), $1, $3 ); }
    ;
declaration: VAR variable_list { $$ = CN1N ( declaration_n, $2 ); };
variable:    IDENTIFIER { $$ = CN0D ( variable_n, STRDUP(yytext) ); };
text:        STRING { $$ = CN0D ( text_n, STRDUP(yytext) ); };
integer:
      NUMBER
      {
        $$ = CN0D ( integer_n, calloc ( 1, sizeof(int32_t) ) );
        *((int32_t *)$$->data) = strtol ( yytext, NULL, 10 );
      }
    ;
%% 

/*
 * This function is called with an error description when parsing fails.
 * Serious error diagnosis requires a lot of code (and imagination), so in the
 * interest of keeping this project on a manageable scale, we just chuck the
 * message/line number on the error stream and stop dead.
 */
int
yyerror ( const char *error )
{
    fprintf ( stderr, "\tError: %s detected at line %d\n", error, yylineno );
    exit ( EXIT_FAILURE );
}
