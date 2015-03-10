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

void removeNode (node_t *node) {
	node_t* temp = node->children[0];
	*node = *temp;		
}

node_t* simplify_tree ( node_t* node ){
    
	if ( node != NULL ){
		int nofChildren = node->n_children;
        	// Recursively simplify the children of the current node
		for ( uint32_t i=0; i<node->n_children; i++ ){
            	node->children[i] = simplify_tree ( node->children[i] );
        	}
        	// After the children have been simplified, we look at the current node
       		// What we do depend upon the type of node
        	switch ( node->type.index ){
            	// These are lists which needs to be flattened. Their structure
            	// is the same, so they can be treated the same way.
            		case FUNCTION_LIST: 
			case STATEMENT_LIST: 
			case PRINT_LIST:
   	       		case EXPRESSION_LIST: 
			case VARIABLE_LIST:
			if (node->n_children == 2) {
				int nofGrandchildren = (node->children[0])->n_children;
				node->n_children = nofChildren-1 + nofGrandchildren;
				node_t** newChildren = (void*)malloc(sizeof(void*)*node->n_children);
				for (int j = 0; j < nofGrandchildren; j++) {
					newChildren[j] = (node->children[0])->children[j];
				}
				newChildren[node->n_children-1] = node->children[1]; 					
				free(node->children[0]);
				free(node->children);
				node->children = newChildren;					
				break;
			}		
			break;


            	// Declaration lists should also be flattened, but their stucture is sligthly
            	// different, so they need their own case
            	case DECLARATION_LIST:
		if (node->n_children == 2) {
			if (node->children[0] != NULL) {				
				int nofGrandchildren = (node->children[0])->n_children;
				node->n_children = nofChildren-1 + nofGrandchildren;
				node_t** newChildren = (void*)malloc(sizeof(void*)*node->n_children);
				for (int j = 0; j < nofGrandchildren; j++) {
					newChildren[j] = (node->children[0])->children[j];
				}
				newChildren[node->n_children-1] = node->children[1]; 					
				free(node->children[0]);
				free(node->children);
				node->children = newChildren;					
			}
			else {
				node->children[0] = node->children[1];
				node->children = (void*)realloc(node->children, sizeof(void*)*1);
				node->n_children = 1;			
			}	
		}                
		break;

            
            	// These have only one child, so they are not needed
            	case STATEMENT: case PARAMETER_LIST: case ARGUMENT_LIST:
		removeNode(node);
		
                	break;


            	// Expressions where both children are integers can be evaluated (and replaced with
            	// integer nodes). Expressions whith just one child can be removed (like statements etc above)
            	case EXPRESSION:
			if (node->n_children == 2) {	
				if ((node->children[0])->type.index == INTEGER && (node->children[1])->type.index == INTEGER) {
					char* temp = (char*)node->data;						
					node->type.index = INTEGER;				
					int* first = (int*)((node->children[0])->data);
					int* second = (int*)((node->children[1])->data);						
					if (temp[0] == '+') {
						*((int*)node->data) = *first + *second; 				
					}
					else if (temp[0] == '-') {
						*((int*)node->data) = *first - *second;
					}
					else if (temp[0] == '*') {
						*((int*)node->data) = *first * *second; 				
					}
					else if (temp[0] == '/') {
						*((int*)node->data) = *first * *second;	 				
					}
					node->n_children = 0;
					free(node->children[0]);
					free(node->children[1]);
					free(node->children);
				} 
			}
			else if (node->n_children == 1) { 
				if (node->data != NULL) {
					char* temp = (char*)node->data;								
					if (temp[0] != '-')removeNode(node);
					else {
						removeNode(node);
						*((int*)node->data) = -*((int*)node->data);
						int* test = (int*)node->data;
						printf("%d\n", *test); 
					}
				}
				else {
					removeNode(node);
				}
			}
                	break;
		}
    	}
    	return node;
}


