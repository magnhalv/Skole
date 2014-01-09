#include "tree.h"
#include "symtab.h"

static int var_offset = -4;
static int counter = 0;

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
        free ( discard->data );
        free ( discard->children );
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




void
bind_names ( node_t *root )
{
	if (root != NULL) {
		switch (root->type.index) {
			
			case PROGRAM:
				program(root);
				break;
			case FUNCTION_LIST:
				bind_functions(root);
				break;
			case FUNCTION:
				function(root);
				break;
			case VARIABLE:
				variable(root);
				break;
			case BLOCK:
				block(root);
				break;
			case DECLARATION:
				declaration(root);
				break;
			case TEXT:
				string(root);
				break;
			default: 
				skipNode(root);
				break;
		
		}

	}
}

//Adds the first scope to the stack, then continues down the tree.
void program (node_t *node) {
	scope_add();
	bind_names(node->children[0]);
	scope_remove();
}

void bind_functions(node_t *node) {
	//Binds all the function names.
	for (int i = 0; i < node->n_children; i++) {
		symbol_t *newSymbol = (void*)malloc(sizeof(void));
		newSymbol->stack_offset = 0;
		newSymbol->label = (char*)(node->children[i]->children[0]->data);
		symbol_insert(newSymbol->label, newSymbol);
	}
	//Continues down the tree. 
	for (int i = 0; i < node->n_children; i++) {
		bind_names(node->children[i]);
	}
}
 
void function (node_t *node) {
	//adds a new scope
	int temp_offset = var_offset;
	var_offset = -4;
	scope_add();
	//Skips the first child(name of the function, since it's already been added in bind_functions(node_t).
	//adds the parameters that lies within the second child. 
	if (node->children[1] != NULL) {
		int offset = 8 + 4*(node->children[1]->n_children-1);
		for (int i = 0; i < (node->children[1])->n_children; i++) {
			symbol_t *new_symbol = (void*)malloc(sizeof(void));;
			new_symbol->stack_offset = offset;
			offset = offset - 4;
			new_symbol->label = NULL;
			symbol_insert((char*)(node->children[1]->children[i]->data), new_symbol);
		}
	}
	//Skips the block node, which is the third child, and jumps directly to its children, since the scope is already added.
	for (int i = 0; i < node->children[2]->n_children; i++) {
		bind_names(node->children[2]->children[i]);
	}
	scope_remove();
	var_offset = temp_offset;
}

//Nothing to add at this node, so skip it and continue down the tree.
void skipNode(node_t *node) {
	for (int i = 0; i < node->n_children; i++) {
		bind_names(node->children[i]);
	}
}

//Adds a new scope and continues down the tree. 
void block(node_t *node) {
	int temp_offset = var_offset;
	var_offset = -4;
	scope_add();
	if (node != NULL) {
		for (int i = 0; i < node->n_children; i++) {
			bind_names(node->children[i]);
		}
	}
	scope_remove();
	var_offset = temp_offset;
}

//Goes down to the child node(which is a VARIABLE_LIST), and adds all it's children to the symbol table.
void declaration(node_t *node) {
	for (int i = 0; i < node->children[0]->n_children; i++) {
		symbol_t *new_symbol = (void*)malloc(sizeof(void));
		new_symbol->stack_offset = var_offset;
		var_offset = var_offset - 4;
		new_symbol->label = NULL;
		symbol_insert((char*)(node->children[0]->children[i]->data), new_symbol);
	}
}

//Looks up the variable in the symbol table.
void variable(node_t *node) {
	char* key = (char*)node->data;
	symbol_t *symbol = symbol_get(key);
}

//Adds string to the string list.
void string (node_t *node) {
	char* str = (char*)node->data;
	node->data = (void*)malloc(sizeof(int));
	*((int*)(node->data)) = strings_add(str);
}
