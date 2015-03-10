#include <tree.h>
#include <generator.h>
#include <string.h>

bool peephole = false;


/* Elements of the low-level intermediate representation */

/* Instructions */
typedef enum {
    STRING, LABEL, PUSH, POP, MOVE, CALL, SYSCALL, LEAVE, RET,
    ADD, SUB, MUL, DIV, JUMP, JUMPZERO, JUMPNONZ, DECL, CLTD, NEG, CMPZERO, NIL,
    CMP, SETL, SETG, SETLE, SETGE, SETE, SETNE, CBW, CWDE,JUMPEQ
} opcode_t;

/* Registers */
static char
*eax = "%eax", *ebx = "%ebx", *ecx = "%ecx", *edx = "%edx",
    *ebp = "%ebp", *esp = "%esp", *esi = "%esi", *edi = "%edi",
    *al = "%al", *bl = "%bl";

/* A struct to make linked lists from instructions */
typedef struct instr {
    opcode_t opcode;
    char *operands[2];
    int32_t offsets[2];
    struct instr *next;
} instruction_t;

/* Start and last element for emitting/appending instructions */
static instruction_t *start = NULL, *last = NULL;

/*
 * Track the scope depth when traversing the tree - init. value may depend on
 * how the symtab was built
 */ 
static int32_t depth = 1;

/* Prototypes for auxiliaries (implemented at the end of this file) */
static void instruction_add ( opcode_t op, char *arg1, char *arg2, int32_t off1, int32_t off2 );
static void instructions_print ( FILE *stream );
static void instructions_finalize ( void );

/* Value used to signal if we've reached a return statement or not. In order to prevent instructions being
* preformed after reaching the first return statement.
*/
static int reachedReturnStatement;
/*
 * Convenience macro to continue the journey through the tree - just to save
 * on duplicate code, not really necessary
 */
#define RECUR() do {\
	for ( int32_t i=0; i<root->n_children; i++ )\
    generate ( stream, root->children[i] );\
} while(false)

/*
 * These macros set implement a function to start/stop the program, with
 * the only purpose of making the call on the first defined function appear
 * exactly as all other function calls.
 */
#define TEXT_HEAD() do {\
    instruction_add ( STRING,       STRDUP("main:"), NULL, 0, 0 );      \
    instruction_add ( PUSH,         ebp, NULL, 0, 0 );                  \
    instruction_add ( MOVE,         esp, ebp, 0, 0 );                   \
    instruction_add ( MOVE,         esp, esi, 8, 0 );                   \
    instruction_add ( DECL,         esi, NULL, 0, 0 );                  \
    instruction_add ( JUMPZERO,     STRDUP("noargs"), NULL, 0, 0 );     \
    instruction_add ( MOVE,         ebp, ebx, 12, 0 );                  \
    instruction_add ( STRING,       STRDUP("pusharg:"), NULL, 0, 0 );   \
    instruction_add ( ADD,          STRDUP("$4"), ebx, 0, 0 );          \
    instruction_add ( PUSH,         STRDUP("$10"), NULL, 0, 0 );        \
    instruction_add ( PUSH,         STRDUP("$0"), NULL, 0, 0 );         \
    instruction_add ( PUSH,         STRDUP("(%ebx)"), NULL, 0, 0 );     \
    instruction_add ( SYSCALL,      STRDUP("strtol"), NULL, 0, 0 );     \
    instruction_add ( ADD,          STRDUP("$12"), esp, 0, 0 );         \
    instruction_add ( PUSH,         eax, NULL, 0, 0 );                  \
    instruction_add ( DECL,         esi, NULL, 0, 0 );                  \
    instruction_add ( JUMPNONZ,     STRDUP("pusharg"), NULL, 0, 0 );    \
    instruction_add ( STRING,       STRDUP("noargs:"), NULL, 0, 0 );    \
} while ( false )

#define TEXT_TAIL() do {\
    instruction_add ( PUSH, eax, NULL, 0, 0 );              \
    instruction_add ( SYSCALL, STRDUP("exit"), NULL, 0, 0 );\
} while ( false )




void generate ( FILE *stream, node_t *root )
{
	//Check if we've reached a return statement earlier. If we have we shall not procede. 
	if (reachedReturnStatement == 1) return;
	int var_offset;
	int var_depth;
	int diff;
	const int BUFFER_LENGTH = 100;
	char buffer[BUFFER_LENGTH];
    int elegant_solution;
    if ( root == NULL )
        return;
    switch ( root->type.index )
    {
		
        case PROGRAM:
            /* Output the data segment */
            strings_output ( stream );
            instruction_add ( STRING, STRDUP( ".text" ), NULL, 0, 0 );

            RECUR();
            TEXT_HEAD();
            /* TODO: Insert a call to the first defined function here */
			instruction_add(CALL, STRDUP((char*)root->children[0]->children[0]->children[0]->data), NULL, 0, 0);
			
			TEXT_TAIL();
            instructions_print ( stream );
            instructions_finalize ();
            break;

        case FUNCTION:
            /*
             * Function definitions:
             * Set up/take down activation record for the function, return value
             */
			instruction_add(LABEL, STRDUP((char*)root->children[0]->entry->label), NULL, 0, 0);
			instruction_add(PUSH, ebp, NULL, 0, 0);
			instruction_add(MOVE, esp, ebp, 0, 0);
			depth++;
			generate(stream, root->children[2]);
			depth--;	
			//We're done with this function, have to reset the reachedReturnStatement value to 0.
			reachedReturnStatement = 0;
			instruction_add(LEAVE, NULL, NULL, 0, 0);			
			instruction_add(RET, NULL, NULL, 0, 0);
			break;

        case BLOCK:
            /*
             * Blocks:
             * Set up/take down activation record, no return value
             */
			instruction_add(PUSH, ebp, NULL, 0, 0);
			instruction_add(MOVE, esp, ebp, 0, 0);
			depth++;			
			RECUR();
			depth--;
			instruction_add(MOVE, ebp, esp, 0, 0);
			instruction_add(POP, ebp, NULL, 0, 0);

            break;

        case DECLARATION:
            /*
             * Declarations:
             * Add space on local stack
             */
			//Moves the stack pointer down 4 bytes for each variable that is to be declared.
			snprintf(buffer, BUFFER_LENGTH, "$%d", (root->children[0]->n_children)*4);
			instruction_add(SUB, STRDUP(buffer), esp, 0, 0);
			
			break;

        case PRINT_LIST:
            /*
             * Print lists:
             * Emit the list of print items, followed by newline (0x0A)
             */
			//Continues down the tree to the print_items.
			RECUR();
			
			//Add new line.
			instruction_add(PUSH, STRDUP("$0x0A"), NULL, 0, 0);
			instruction_add(SYSCALL, STRDUP("putchar"), NULL, 0, 0);
			instruction_add(ADD, STRDUP("$4"), esp, 0, 0);
            break;

        case PRINT_ITEM:
            /*
             * Items in print lists:
             * Determine what kind of value (string literal or expression)
             * and set up a suitable call to printf
             */
			//Set up a suitable call for strings to printf.
			if (root->children[0]->type.index == TEXT){
				snprintf(buffer, BUFFER_LENGTH, "$.STRING%d", *((int*)root->children[0]->data)); 
				instruction_add(PUSH, STRDUP(buffer), NULL, 0, 0);
				instruction_add(SYSCALL, STRDUP("printf"), NULL, 0, 0);
				instruction_add(ADD, STRDUP("$4"), esp, 0, 0);
				
			}
			//Set up a suitable call for integers to printf.
			else {
				generate(stream, root->children[0]);
				instruction_add(PUSH, STRDUP("$.INTEGER"), NULL, 0, 0);
				instruction_add(SYSCALL, STRDUP("printf"), NULL, 0, 0);
				instruction_add(ADD, STRDUP("$8"), esp, 0, 0);
			}
            break;
		
        case EXPRESSION:
            /*
             * Expressions:
             * Handle any nested expressions first, then deal with the
             * top of the stack according to the kind of expression
             * (single variables/integers handled in separate switch/cases)
             */

			evaluate_expression(stream, root);

			break;

        case VARIABLE:
            /*
             * Occurrences of variables: (declarations have their own case)
             * - Find the variable's stack offset
             * - If var is not local, unwind the stack to its correct base
             */
			//Variables depth and offset.
			var_offset = root->entry->stack_offset;
			var_depth = root->entry->depth;
			diff = depth - var_depth;
			
			//Uses ebx to find the correct frame. 
			instruction_add(MOVE, ebp, ebx, 0, 0);
			for (int i = 0; i < diff; i++) {
				instruction_add(MOVE, STRDUP("(%ebx)"), ebx, 0, 0);		
			}
			//Pushes the value of the variable on the stack.
			instruction_add(PUSH, ebx, NULL, var_offset, 0);
            break;

        case INTEGER:
            /*
             * Integers: constants which can just be put on stack
             */
			//Creates the correct string for the integer, and pushes it on the stack.
			snprintf(buffer, BUFFER_LENGTH, "$%d", *((int*)root->data));
			instruction_add(PUSH, STRDUP(buffer), NULL, 0, 0);
				break;

        case ASSIGNMENT_STATEMENT:
            /*
             * Assignments:
             * Right hand side is an expression, find left hand side on stack
             * (unwinding if necessary)
             */
			//Evaluates the expression on the right side. Its value will be on top of stack afterwards, so pop it.
			generate(stream, root->children[1]);
			instruction_add(POP, eax, NULL, 0, 0);
			
			
			var_offset = root->children[0]->entry->stack_offset;
			var_depth = root->children[0]->entry->depth;
			diff = depth - var_depth;
			
			//Puts the adress to the next frame in ebx, and unwind until we find the variable's location.
			instruction_add(MOVE, ebp, ebx, 0, 0);
			for (int i = 0; i < diff; i++) {
				instruction_add(MOVE, STRDUP("(%ebx)"), ebx, 0, 0);		
			}
			//Put the expression value in the location of the variable.
			instruction_add(MOVE, eax, ebx, 0, var_offset);
				break;

        case RETURN_STATEMENT:
            /*
             * Return statements:
             * Evaluate the expression and put it in EAX
             */
			//Evalute the expression. Its value will be on stack afterwards, so pop it.
			RECUR();
			instruction_add(POP, eax, NULL, 0, 0);
			//Signal that we have reached a return statement. No more instructions should be added for this
			//procedure. 
			reachedReturnStatement = 1;
            break;

        default:
            /* Everything else can just continue through the tree */
            RECUR();
            break;
    }
}

void evaluate_expression( FILE *stream, node_t *root ) {
	//If we've reached a function, call it. 
	if (*((char *)root->data) == 'F') {
		node_t *para_list = root->children[1];
		//Pushes the children on stack		
		generate(stream, para_list);
		//Calls the function
		instruction_add(CALL, STRDUP((char*)root->children[0]->entry->label), NULL, 0, 0);
		//Pushes the return value on stack.
		instruction_add(PUSH, eax, NULL, 0, 0);
		return;
	}
	RECUR();
	//Uminus. 
	if (root->n_children == 1 && root->data != NULL) {
		instruction_add(POP, eax, NULL, 0, 0);
		instruction_add(NEG, eax, NULL, 0, 0);
		instruction_add(PUSH, eax, NULL, 0, 0);
		return;
	}
	//Normal arithmetic. 
	instruction_add(POP, ebx, NULL, 0, 0);
	instruction_add(POP, eax, NULL, 0, 0);
	//First we deal with operands with a single char.
	if(strlen((char*)root->data) == 1){
		switch ( *((char *)root->data) ) {
            case '+':  
				instruction_add(ADD, ebx, eax, 0, 0);
				break;
            case '-':  
				instruction_add(SUB, ebx, eax, 0, 0);				
				break;
            case '*':  
				instruction_add(MUL, ebx, NULL, 0, 0);			
				break;
            case '/':  
				instruction_add(CLTD, NULL, NULL, 0, 0);
				instruction_add(DIV, ebx, NULL, 0, 0);
				break;
            case '>': 
				instruction_add(CMP, ebx, eax, 0, 0);					
				instruction_add(SETG, al, NULL, 0, 0);
				instruction_add(CBW, NULL, NULL, 0, 0);
				instruction_add(CWDE, NULL, NULL, 0, 0);
				break;
            case '<':  
				instruction_add(CMP, ebx, eax, 0, 0);
				instruction_add(SETL, al, NULL, 0, 0);
				instruction_add(CBW, NULL, NULL, 0, 0);
				instruction_add(CWDE, NULL, NULL, 0, 0);							
				break;
					
        }
    }
	//Then we deal with operands with two chars. 
	else{
		RECUR();
        switch ( *((char *)root->data) ){
			case '=':
				instruction_add(CMP, eax, ebx, 0, 0);
				instruction_add(SETE, al, NULL, 0, 0);
				instruction_add(CBW, NULL, NULL, 0, 0);
				instruction_add(CWDE, NULL, NULL, 0, 0);								
				break;
            case '!':  
				instruction_add(CMP, eax, ebx, 0, 0);				
				instruction_add(SETNE, al, NULL, 0, 0);
				instruction_add(CBW, NULL, NULL, 0, 0);
				instruction_add(CWDE, NULL, NULL, 0, 0);							
				break;
            case '<':  
				instruction_add(CMP, ebx, eax, 0, 0);
				instruction_add(SETLE, al, NULL, 0, 0);
				instruction_add(CBW, NULL, NULL, 0, 0);
				instruction_add(CWDE, NULL, NULL, 0, 0);
				break;
				
            case '>':  
				instruction_add(CMP, ebx, eax, 0, 0);
				instruction_add(SETGE, al, NULL, 0, 0);
				instruction_add(CBW, NULL, NULL, 0, 0);
				instruction_add(CWDE, NULL, NULL, 0, 0);			
				break;
                }
	}
	instruction_add(PUSH, eax, NULL, 0, 0);	
}

/* Provided auxiliaries... */


    static void
instruction_append ( instruction_t *next )
{
    if ( start != NULL )
    {
        last->next = next;
        last = next;
    }
    else
        start = last = next;
}


    static void
instruction_add (
        opcode_t op, char *arg1, char *arg2, int32_t off1, int32_t off2 
        )
{
    instruction_t *i = (instruction_t *) malloc ( sizeof(instruction_t) );
    *i = (instruction_t) { op, {arg1, arg2}, {off1, off2}, NULL };
    instruction_append ( i );
}


    static void
instructions_print ( FILE *stream )
{
    instruction_t *this = start;
    while ( this != NULL )
    {
        switch ( this->opcode )
        {
            case PUSH:
                if ( this->offsets[0] == 0 )
                    fprintf ( stream, "\tpushl\t%s\n", this->operands[0] );
                else
                    fprintf ( stream, "\tpushl\t%d(%s)\n",
                            this->offsets[0], this->operands[0]
                            );
                break;
            case POP:
                if ( this->offsets[0] == 0 )
                    fprintf ( stream, "\tpopl\t%s\n", this->operands[0] );
                else
                    fprintf ( stream, "\tpopl\t%d(%s)\n",
                            this->offsets[0], this->operands[0]
                            );
                break;
            case MOVE:
                if ( this->offsets[0] == 0 && this->offsets[1] == 0 )
                    fprintf ( stream, "\tmovl\t%s,%s\n",
                            this->operands[0], this->operands[1]
                            );
                else if ( this->offsets[0] != 0 && this->offsets[1] == 0 )
                    fprintf ( stream, "\tmovl\t%d(%s),%s\n",
                            this->offsets[0], this->operands[0], this->operands[1]
                            );
                else if ( this->offsets[0] == 0 && this->offsets[1] != 0 )
                    fprintf ( stream, "\tmovl\t%s,%d(%s)\n",
                            this->operands[0], this->offsets[1], this->operands[1]
                            );
                break;

            case ADD:
                if ( this->offsets[0] == 0 && this->offsets[1] == 0 )
                    fprintf ( stream, "\taddl\t%s,%s\n",
                            this->operands[0], this->operands[1]
                            );
                else if ( this->offsets[0] != 0 && this->offsets[1] == 0 )
                    fprintf ( stream, "\taddl\t%d(%s),%s\n",
                            this->offsets[0], this->operands[0], this->operands[1]
                            );
                else if ( this->offsets[0] == 0 && this->offsets[1] != 0 )
                    fprintf ( stream, "\taddl\t%s,%d(%s)\n",
                            this->operands[0], this->offsets[1], this->operands[1]
                            );
                break;
            case SUB:
                if ( this->offsets[0] == 0 && this->offsets[1] == 0 )
                    fprintf ( stream, "\tsubl\t%s,%s\n",
                            this->operands[0], this->operands[1]
                            );
                else if ( this->offsets[0] != 0 && this->offsets[1] == 0 )
                    fprintf ( stream, "\tsubl\t%d(%s),%s\n",
                            this->offsets[0], this->operands[0], this->operands[1]
                            );
                else if ( this->offsets[0] == 0 && this->offsets[1] != 0 )
                    fprintf ( stream, "\tsubl\t%s,%d(%s)\n",
                            this->operands[0], this->offsets[1], this->operands[1]
                            );
                break;
            case MUL:
                if ( this->offsets[0] == 0 )
                    fprintf ( stream, "\timull\t%s\n", this->operands[0] );
                else
                    fprintf ( stream, "\timull\t%d(%s)\n",
                            this->offsets[0], this->operands[0]
                            );
                break;
            case DIV:
                if ( this->offsets[0] == 0 )
                    fprintf ( stream, "\tidivl\t%s\n", this->operands[0] );
                else
                    fprintf ( stream, "\tidivl\t%d(%s)\n",
                            this->offsets[0], this->operands[0]
                            );
                break;
            case NEG:
                if ( this->offsets[0] == 0 )
                    fprintf ( stream, "\tnegl\t%s\n", this->operands[0] );
                else
                    fprintf ( stream, "\tnegl\t%d(%s)\n",
                            this->offsets[0], this->operands[0]
                            );
                break;

            case DECL:
                fprintf ( stream, "\tdecl\t%s\n", this->operands[0] );
                break;
            case CLTD:
                fprintf ( stream, "\tcltd\n" );
                break;
            case CBW:
                fprintf ( stream, "\tcbw\n" );
                break;
            case CWDE:
                fprintf ( stream, "\tcwde\n" );
                break;
            case CMPZERO:
                if ( this->offsets[0] == 0 )
                    fprintf ( stream, "\tcmpl\t$0,%s\n", this->operands[0] );
                else
                    fprintf ( stream, "\tcmpl\t$0,%d(%s)\n",
                            this->offsets[0], this->operands[0]
                            );
                break;
            case CMP:
                if ( this->offsets[0] == 0 && this->offsets[1] == 0 )
                    fprintf ( stream, "\tcmpl\t%s,%s\n",
                            this->operands[0], this->operands[1]
                            );
                else if ( this->offsets[0] != 0 && this->offsets[1] == 0 )
                    fprintf ( stream, "\tcmpl\t%d(%s),%s\n",
                            this->offsets[0], this->operands[0], this->operands[1]
                            );
                else if ( this->offsets[0] == 0 && this->offsets[1] != 0 )
                    fprintf ( stream, "\tcmpl\t%s,%d(%s)\n",
                            this->operands[0], this->offsets[1], this->operands[1]
                            );
                break;
            case SETL:
                if ( this->offsets[0] == 0 )
                    fprintf ( stream, "\tsetl\t%s\n", this->operands[0] );
                else
                    fprintf ( stream, "\tsetl\t%d(%s)\n",
                            this->offsets[0], this->operands[0]
                            );
                break;
            case SETG:
                if ( this->offsets[0] == 0 )
                    fprintf ( stream, "\tsetg\t%s\n", this->operands[0] );
                else
                    fprintf ( stream, "\tsetg\t%d(%s)\n",
                            this->offsets[0], this->operands[0]
                            );
                break;
            case SETLE:
                if ( this->offsets[0] == 0 )
                    fprintf ( stream, "\tsetle\t%s\n", this->operands[0] );
                else
                    fprintf ( stream, "\tsetle\t%d(%s)\n",
                            this->offsets[0], this->operands[0]
                            );
                break;
            case SETGE:
                if ( this->offsets[0] == 0 )
                    fprintf ( stream, "\tsetge\t%s\n", this->operands[0] );
                else
                    fprintf ( stream, "\tsetge\t%d(%s)\n",
                            this->offsets[0], this->operands[0]
                            );
                break;
            case SETE:
                if ( this->offsets[0] == 0 )
                    fprintf ( stream, "\tsete\t%s\n", this->operands[0] );
                else
                    fprintf ( stream, "\tsete\t%d(%s)\n",
                            this->offsets[0], this->operands[0]
                            );
                break;
            case SETNE:
                if ( this->offsets[0] == 0 )
                    fprintf ( stream, "\tsetne\t%s\n", this->operands[0] );
                else
                    fprintf ( stream, "\tsetne\t%d(%s)\n",
                            this->offsets[0], this->operands[0]
                            );
                break;

            case CALL: case SYSCALL:
                fprintf ( stream, "\tcall\t" );
                if ( this->opcode == CALL )
                    fputc ( '_', stream );
                fprintf ( stream, "%s\n", this->operands[0] );
                break;
            case LABEL: 
                fprintf ( stream, "_%s:\n", this->operands[0] );
                break;

            case JUMP:
                fprintf ( stream, "\tjmp\t%s\n", this->operands[0] );
                break;
            case JUMPZERO:
                fprintf ( stream, "\tjz\t%s\n", this->operands[0] );
                break;
            case JUMPEQ:
                fprintf ( stream, "\tje\t%s\n", this->operands[0] );
                break;
            case JUMPNONZ:
                fprintf ( stream, "\tjnz\t%s\n", this->operands[0] );
                break;

            case LEAVE: fputs ( "\tleave\n", stream ); break;
            case RET:   fputs ( "\tret\n", stream );   break;

            case STRING:
                        fprintf ( stream, "%s\n", this->operands[0] );
                        break;

            case NIL:
                        break;

            default:
                        fprintf ( stderr, "Error in instruction stream\n" );
                        break;
        }
        this = this->next;
    }
}


    static void
instructions_finalize ( void )
{
    instruction_t *this = start, *next;
    while ( this != NULL )
    {
        next = this->next;
        if ( this->operands[0] != eax && this->operands[0] != ebx &&
                this->operands[0] != ecx && this->operands[0] != edx &&
                this->operands[0] != ebp && this->operands[0] != esp &&
                this->operands[0] != esi && this->operands[0] != edi &&
                this->operands[0] != al && this->operands[0] != bl 
           ) 
            free ( this->operands[0] );
		free ( this );
        this = next;
    }
}