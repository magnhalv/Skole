#include "tree.h"
#include "symtab.h"


#ifdef DUMP_TREES
void
node_print ( FILE *output, node_t *root, uint32_t nesting )
{
    if ( root != NULL )
    {
        fprintf ( output, "%*c%s", nesting, ' ', root->type.text );
        if ( root->type.index == INTEGER )
            fprintf ( output, "(%d)", *((int32_t *)root->data) );
        if ( root->type.index == VARIABLE || root->type.index == EXPRESSION )
        {
            if ( root->data != NULL )
                fprintf ( output, "(\"%s\")", (char *)root->data );
            else
                fprintf ( output, "%p", root->data );
        }
        fputc ( '\n', output );
        for ( int32_t i=0; i<root->n_children; i++ )
            node_print ( output, root->children[i], nesting+1 );
    }
    else
        fprintf ( output, "%*c%p\n", nesting, ' ', root );
}
#endif


node_t *
node_init ( node_t *nd, nodetype_t type, void *data, uint32_t n_children, ... )
{
    va_list child_list;
    *nd = (node_t) { type, data, NULL, n_children,
        (node_t **) malloc ( n_children * sizeof(node_t *) )
    };
    va_start ( child_list, n_children );
    for ( uint32_t i=0; i<n_children; i++ )
        nd->children[i] = va_arg ( child_list, node_t * );
    va_end ( child_list );
    return nd;
}


void
node_finalize ( node_t *discard )
{
    if ( discard != NULL )
    {
        free ( discard->data ), free ( discard->children );
        free ( discard );
    }
}


void
destroy_subtree ( node_t *discard )
{
    if ( discard != NULL )
    {
        for ( uint32_t i=0; i<discard->n_children; i++ )
            destroy_subtree ( discard->children[i] );
        node_finalize ( discard );
    }
}


node_t *
simplify_tree ( node_t *root )
{
    node_t *result = root;

    /*
     * First, we ensure that we have a node to look at. This has the
     * convenient side-effect that optional elements in the syntax
     * remain marked by a NULL placeholder in the tree, keeping it simple
     * to recognize the structures imposed by the grammar.
     */
    if ( root != NULL )
    {
        /* Recur before treating any single node: depth-first traversal */
        for ( uint32_t i=0; i<root->n_children; i++ )
            root->children[i] = simplify_tree ( root->children[i] );

        /* Here is where we do something to the lowest nodes in the tree */
        switch ( root->type.index )
        {
            /*
             * These types have only syntactic value, so we can throw
             * them out now:
             * STATEMENT always has one child, which can identify itself
             * PARAMETER_LIST only serves to make variable lists optional
             *                in function declarations
             * ARGUMENT_LIST does the same thing for function calls
             */
            case STATEMENT: case PARAMETER_LIST: case ARGUMENT_LIST:
                result = root->children[0];
                node_finalize ( root );
                break;

            /*
             * DECLARATION_LIST can be NULL altogether, but we preserved
             * that at the beginning of the function. This has a somewhat
             * nasty side-effect in the grammar, however, as it gets a
             * different structure from the other lists when it DOES exist
             * (such as here). Other lists have a single-element list with
             * the last list item at the bottom of the tree, whereas
             * declaration lists have a 2-element list with NULL and the
             * last item. The code that follows molds the bottom of a
             * declaration list into the same form as the other lists, so
             * the rest can be handled by the otherwise standard
             * list-flattening code.
             */
            case DECLARATION_LIST:
                if ( root->children[0] == NULL )
                {
                    root->children[0] = root->children[1];
                    root->n_children--;
                    root->children = realloc (
                        root->children, root->n_children * sizeof(node_t *)
                    );
                }
                /* NB! There is no 'break' here on purpose - since the
                 * declaration list is now in the standard form, we WANT
                 * control to fall through to the standard list-handling
                 * code below.
                 */

            /*
             * All these lists have the same structure, so general flattening
             * is quite simple: extend the left child's list with the right
             * child, and substitute the parent.
             */
            case FUNCTION_LIST: case STATEMENT_LIST: case PRINT_LIST:
            case EXPRESSION_LIST: case VARIABLE_LIST:
                if ( root->n_children >= 2 )
                {
                    result = root->children[0];
                    uint32_t n = (result->n_children += 1);
                    result->children =
                        realloc ( result->children, n * sizeof(node_t *) );
                    result->children[n-1] = root->children[1];
                    node_finalize ( root );
                }
                break;

            case EXPRESSION:
                switch ( root->n_children )
                {
                    case 1:
                    	if( root->data == NULL){
                            result = root->children[0];
                            node_finalize(root);
                        }

                        else if ( root->children[0]->type.index == INTEGER )
                        {
                            result = root->children[0];
                            if ( root->data != NULL )   /* Unary minus */
                                *((int32_t *)result->data) *= -1;
                            node_finalize ( root );
                        }
                        break;
                    case 2:     /* Constant binary expressions */
                        if ( root->children[0]->type.index == INTEGER &&
                             root->children[1]->type.index == INTEGER &&
                             root->data != NULL
                        ) {
                            result = root->children[0];
                            int32_t
                                *a = result->data,
                                *b = root->children[1]->data;
                            if(strlen((char*)root->data) == 1){
                                switch ( *((char *)root->data) )
                                {
                                    case '+': *a += *b; break;
                                    case '-': *a -= *b; break;
                                    case '*': *a *= *b; break;
                                    case '/': *a /= *b; break;
                                    case '<': *a = (*a < *b); break;
                                    case '>': *a = (*a > *b); break;
                                }
                            }
                            else{
                                switch ( *((char *)root->data) )
                                {
                                    case '=': *a = (*a == *b); break;
                                    case '!': *a = (*a != *b); break;
                                    case '<': *a = (*a <= *b); break;
                                    case '>': *a = (*a >= *b); break;
                                }
                            }

                            node_finalize ( root->children[1] );
                            node_finalize ( root );
                        }
                        break;
                }
                break;
        }
    }
    return result;
}


void
bind_names ( node_t *root )
{
    if ( root != NULL )
    {
        switch ( root->type.index )
        {
            case FUNCTION_LIST:
                /*
                * Here we need to initialize tables for all the functions in
                * the program, in order to resolve forward references later
                */
                scope_add ();
                for ( uint32_t i=0; i<root->n_children; i++ )
                {
                    /* Create a symbol for the function */
                    /* Duplicating label data here, but never mind... */
                    node_t *funname = root->children[i]->children[0];
                    funname->entry = malloc ( sizeof(symbol_t) );
                    *(funname->entry) = (symbol_t) { .label= STRDUP(funname->data), .stack_offset=0 };
                    symbol_insert (funname->data, funname->entry);
                }
                for ( uint32_t i=0; i<root->n_children; i++ )
                    bind_names ( root->children[i] );
                scope_remove ();
                break;

            case FUNCTION:
                {
                    /* Skip the name of the function - done in FUNCTION_LIST */
                    /* Declare the formal parameter variables */
                    scope_add ();
                    node_t *paramlist = root->children[1];
                    if ( paramlist != NULL )
                    {
                        int32_t offset = 4 + 4*paramlist->n_children;
                        for ( uint32_t i=0; i<paramlist->n_children; i++ )
                        {
                            node_t *param = paramlist->children[i];
                            param->entry = (symbol_t *)malloc(sizeof(symbol_t));
                            *(param->entry) = (symbol_t) { .stack_offset = offset, .label = NULL };
                            symbol_insert ( param->data, param->entry );
                            offset -= 4;
                        }
                    }
                    bind_names ( root->children[2] );
                    scope_remove ();
                }
                break;

            case BLOCK:
                scope_add ();
                for ( uint32_t i=0; i<root->n_children; i++ )
                    bind_names ( root->children[i] );
                scope_remove ();
                break;

            case DECLARATION_LIST:
                {
                    int32_t offset = -4;
                    for ( uint32_t d=0; d<root->n_children; d++ )
                    {
                        node_t *dnode = root->children[d];
                        node_t *varlist = dnode->children[0];
                        for ( uint32_t i=0; i<varlist->n_children; i++ )
                        {
                            node_t *var = varlist->children[i];
                            var->entry = (symbol_t *) malloc (sizeof(symbol_t));
                            *(var->entry) = (symbol_t) {
                                .label = NULL, .stack_offset = offset
                            };
                            symbol_insert (var->data, var->entry);
                            offset -= 4;
                        }
                    }
                }
                break;

            case VARIABLE:
                root->entry = symbol_get ( root->data );
                if ( root->entry == NULL )
                {
                    fprintf ( stderr,
                        "Unknown identifier '%s'\n", (char *)root->data
                    );
                    exit ( EXIT_FAILURE );
                }
                break;

            case TEXT:
                {
                    int32_t i = strings_add ( root->data );
                    root->data = malloc ( sizeof( int32_t ) );
                    *((int32_t *)root->data) = i;
                }
                break;

            default:
                for ( uint32_t i=0; i<root->n_children; i++ )
                    bind_names ( root->children[i] );
                break;
        }
    }
}
