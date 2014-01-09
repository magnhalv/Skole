#include "tree.h"


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


node_t * node_init ( node_t *nd, nodetype_t type, void *data, uint32_t n_children, ... ) {
	nd->data = data;
	nd->type = type;
	nd->entry = NULL;
	nd->n_children = n_children;
	if (n_children > 0) {
		nd->children = (void*)malloc(sizeof(void*)*n_children); //*void ?
		va_list args;
		va_start(args, n_children);
		for (int i = 0; i < n_children; i++) {
			nd->children[i] = va_arg(args, node_t*);
		}
		va_end(args);
	}
	else {
		nd->children = NULL;
	}
	return nd;


}


void node_finalize ( node_t *discard ) {
	free(discard->children);
	discard->children = NULL;
	free(discard);
	discard = NULL;
	
}


void destroy_subtree ( node_t *discard ){
	if (discard->n_children != 0) {
		for (int i = 0; i < discard->n_children; i++) {
			destroy_subtree(discard->children[i]);
		}
	}
	node_finalize(discard);
}


