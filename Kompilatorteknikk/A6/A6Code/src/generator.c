#include <tree.h>
#include <generator.h>

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
//Used to find variables in other frames
int32_t depth_difference;

/* Prototypes for auxiliaries (implemented at the end of this file) */
static void instruction_add ( opcode_t op, char *arg1, char *arg2, int32_t off1, int32_t off2 );
static void instructions_print ( FILE *stream );
static void instructions_finalize ( void );


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
    instruction_add ( LEAVE, NULL, NULL, 0, 0 );            \
    instruction_add ( PUSH, eax, NULL, 0, 0 );              \
    instruction_add ( SYSCALL, STRDUP("exit"), NULL, 0, 0 );\
} while ( false )

static int n_for = 0;
static int n_if = 0;
static int n_while = 0;
static char *func_name = NULL;



void generate ( FILE *stream, node_t *root )
{
	int length = 0;
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

            instruction_add(CALL, root->children[0]->children[0]->children[0]->entry->label, NULL, 0, 0);

            TEXT_TAIL();

            instructions_print ( stream );
            instructions_finalize ();
			
            break;

        case FUNCTION:
            /*
             * Function definitions:
             * Set up/take down activation record for the function, return value
             */

            //Entering new scope, 'depth' is the depth of the current scope
            depth++;

          
            int len = strlen(root->children[0]->entry->label);
			
			//Generating the string needed for the label instruction
			func_name = (char*) malloc(sizeof(char)*len);
			strncpy(func_name, root->children[0]->entry->label, len);
			
            char *temp = (char*) malloc(sizeof(char) * (len + 3));
            temp[0] = '_';
            for(int c = 0; c < len; c++){
                temp[c+1] = root->children[0]->entry->label[c];
            }
            temp[len + 1] = ':';
            temp[len + 2] = 0;

            //Generate the label for the function, and the code to update the base ptr
            instruction_add(STRING, temp, NULL, 0, 0);
            instruction_add(PUSH, ebp, NULL, 0,0);
            instruction_add(MOVE, esp, ebp, 0,0);

            //Generating code for the functions body
            //The body is the last child, the other children are the name of the function
            //the arguments etc
            generate(stream, root->children[root->n_children - 1]);

            //Generating code to restore the base ptr, and to return
            instruction_add(LEAVE, NULL, NULL, 0,0);
            instruction_add(RET, NULL, NULL, 0,0);
			
			free(func_name);
			
			
            //Leaving the scope, decreasing depth
            depth--;
            break;

        case BLOCK:
            /*
             * Blocks:
             * Set up/take down activation record, no return value
             */

            //Entering new scope
            depth++;

            //Setting up the new activation record
            instruction_add(PUSH, ebp, NULL, 0,0);
            instruction_add(MOVE, esp, ebp, 0,0);

            //Generating code for the body of the block
            RECUR();

            //Restoring the old activation record
            instruction_add(LEAVE, NULL, NULL, 0,0);

            //Leaving scope
            depth--;
            break;

        case DECLARATION:
            /*
             * Declarations:
             * Add space on local stack
             */

            //The declarations first child is a VARIABLE_LIST, the number of children
            //of the VARIABLE_LIST is the number of variables declared. A 0 is pushed on
            //the stack for each
            for(uint32_t c = 0; c < root->children[0]->n_children; c++){
                instruction_add(PUSH, STRDUP("$0"), NULL, 0,0);
            }
            break;

        case PRINT_LIST:
            /*
             * Print lists:
             * Emit the list of print items, followed by newline (0x0A)
             */

            //Generate code for all the PRINT_ITEMs
            RECUR();

            //Print a newline, push the newline, call 'putchar', and pop the argument
            //(overwriting the value returned from putchar...)
            instruction_add(PUSH, STRDUP("$0x0A"), NULL, 0, 0);
            instruction_add(SYSCALL, STRDUP("putchar"), NULL, 0,0);
            instruction_add(POP, eax, NULL, 0,0);
            break;

        case PRINT_ITEM:
            /*
             * Items in print lists:
             * Determine what kind of value (string literal or expression)
             * and set up a suitable call to printf
             */

            //Checking type of value, (of the child of the PRINT_ITEM,
            //which is what is going to be printed
            if(root->children[0]->type.index == TEXT){
                //String, need to push '$.STRINGx' where x is the number of the string
                //The number can be found in the nodes data field, and must be transformed
                //to a string, and concatenated with the '$.STRING' part
                int32_t t = *((int32_t*)root->children[0]->data);
                char int_part[3]; //can have more than 999 strings...
                sprintf(int_part, "%d", t);
                char str_part[9] = "$.STRING";
                strcat(str_part, int_part);

                //Generating the instructions, pushing the argument of printf
                //(the string), calling printf, and removing the argument from
                //the stack (overwriting the returnvalue from printf)
                instruction_add(PUSH, STRDUP(str_part), NULL, 0,0);
                instruction_add(SYSCALL, STRDUP("printf"), NULL, 0,0);
                instruction_add(POP, eax,NULL,0,0);
            }
            else{
                //If the PRINT_ITEMs child isn't a string, it's an expression
                //The expression is evaluated, and its result, which is an integer
                //is printed

                //Evaluating the expression, the result is placed at the top of the stack
                RECUR();

                //Pushing the .INTEGER constant, which will be the second argument to printf,
                //and cause the first argument, which is the result of the expression, and is
                //allready on the stack to be printed as an integer
                instruction_add(PUSH, STRDUP("$.INTEGER"), NULL, 0,0);
                instruction_add(SYSCALL, STRDUP("printf"), NULL,0,0);

                //Poping both the arguments to printf
                instruction_add(POP, eax, NULL, 0,0);
                instruction_add(POP, eax, NULL, 0,0);
            }


            break;

        case EXPRESSION:
            /*
             * Expressions:
             * Handle any nested expressions first, then deal with the
             * top of the stack according to the kind of expression
             * (single variables/integers handled in separate switch/cases)
             */


            switch (root->n_children){
                case 1:
                    //One child, and some data, this is the -exp expression
                    if(root->data != NULL){
                        //Computing the exp part of -exp, the result is placed on the top of the stack
                        RECUR();

                        //Negating the exp by computing 0 - exp
                        instruction_add(POP, ebx, NULL, 0,0);
                        instruction_add(MOVE, STRDUP("$0"), eax, 0,0);
                        instruction_add(SUB, ebx, eax, 0,0);

                        //Pushing the result on the stack
                        instruction_add(PUSH, eax, NULL, 0,0);
                    }
                    else{
                        //One child, and no data, this is variables
                        //They are handeled later
                        RECUR();
                    }
                    break;

                case 2:
                    //Two children and no data, a function (call, not defenition)
                    if(*(char*)(root->data) == 'F'){
                        //Generate the code for the second child, the arguments, this will place them on the stack
                        generate(stream, root->children[1]);

                        //The call instruction
                        instruction_add(CALL, STRDUP(root->children[0]->entry->label), NULL, 0,0);

                        //Removing the arguments, changing the stack pointer directly, rather than poping
                        //since the arguments aren't needed
                        if(root->children[1] != NULL){
                          for(int c = 0; c < root->children[1]->n_children; c++){
                            instruction_add(ADD, STRDUP("$4"), esp, 0,0);
                          }
                        }

                        //Pushing the returnvalue from the function on the stack
                        instruction_add(PUSH, eax, NULL, 0, 0);
                        break;
                    }


                    //Two children and data, this is the arithmetic expressions
                    //The two children are evaluated first, which places their values
                    //at the top of the stack. More precisely, the result of the second
                    //subexpression will be placed at the top of the stack, the result of
                    //the first on the position below it
                    RECUR();
                    if(strlen((char*)root->data) == 1){
                        switch (*(char*)root->data){

                            // Addition and subtraction is handeled equally
                            // The arguments are placed in the eax and ebx registers
                            // they are added/subtracted, and the result is pushed on the stack
                            case '+':
                                instruction_add(POP, eax, NULL, 0,0);
                                instruction_add(POP, ebx, NULL, 0,0);
                                instruction_add(ADD, ebx, eax, 0,0);
                                instruction_add(PUSH, eax, NULL, 0,0);
                                break;
                            case '-':
                                instruction_add(POP, ebx, NULL, 0,0);
                                instruction_add(POP, eax, NULL, 0,0);
                                instruction_add(SUB, ebx, eax, 0,0);
                                instruction_add(PUSH, eax, NULL, 0,0);
                                break;

                                //With multiplication/division it's also necessary to sign extend the
                                //arguments, using the CLTD instruction, the MUL/DIV instructions only need
                                //one argument, the other one is eax
                            case '*':
                                instruction_add(POP, eax, NULL, 0,0);
                                instruction_add(POP, ebx, NULL, 0,0);
                                instruction_add(CLTD, NULL, NULL, 0,0);
                                instruction_add(MUL, ebx, NULL, 0,0);
                                instruction_add(PUSH, eax, NULL, 0,0);
                                break;
                            case '/':
                                instruction_add(POP, ebx, NULL, 0,0);
                                instruction_add(POP, eax, NULL, 0,0);
                                instruction_add(CLTD, NULL, NULL, 0,0);
                                instruction_add(DIV, ebx, NULL, 0,0);
                                instruction_add(PUSH, eax, NULL, 0,0);
                                break;
                            case '>':
                                instruction_add(POP, ebx, NULL, 0,0);
                                instruction_add(POP, eax, NULL, 0,0);
                                instruction_add(CMP, ebx, eax, 0,0);
                                instruction_add(SETG, al, NULL, 0,0);
                                instruction_add(CBW, NULL, NULL, 0,0);
                                instruction_add(CWDE, NULL, NULL, 0,0);
                                instruction_add(PUSH, eax, NULL, 0,0);
                                break;
                            case '<':
                                instruction_add(POP, ebx, NULL, 0,0);
                                instruction_add(POP, eax, NULL, 0,0);
                                instruction_add(CMP, ebx, eax, 0,0);
                                instruction_add(SETL, al, NULL, 0,0);
                                instruction_add(CBW, NULL, NULL, 0,0);
                                instruction_add(CWDE, NULL, NULL, 0,0);
                                instruction_add(PUSH, eax, NULL, 0,0);
                                break;
                        }

                    }
                    else{
                        switch (*(char*)root->data){
                            case '>':
                                instruction_add(POP, ebx, NULL, 0,0);
                                instruction_add(POP, eax, NULL, 0,0);
                                instruction_add(CMP, ebx, eax, 0,0);
                                instruction_add(SETGE, al, NULL, 0,0);
                                instruction_add(CBW, NULL, NULL, 0,0);
                                instruction_add(CWDE, NULL, NULL, 0,0);
                                instruction_add(PUSH, eax, NULL, 0,0);
                                break;
                            case '<':
                                instruction_add(POP, ebx, NULL, 0,0);
                                instruction_add(POP, eax, NULL, 0,0);
                                instruction_add(CMP, ebx, eax, 0,0);
                                instruction_add(SETLE, al, NULL, 0,0);
                                instruction_add(CBW, NULL, NULL, 0,0);
                                instruction_add(CWDE, NULL, NULL, 0,0);
                                instruction_add(PUSH, eax, NULL, 0,0);
                                break;
                            case '=':
                                instruction_add(POP, ebx, NULL, 0,0);
                                instruction_add(POP, eax, NULL, 0,0);
                                instruction_add(CMP, ebx, eax, 0,0);
                                instruction_add(SETE, al, NULL, 0,0);
                                instruction_add(CBW, NULL, NULL, 0,0);
                                instruction_add(CWDE, NULL, NULL, 0,0);
                                instruction_add(PUSH, eax, NULL, 0,0);
                                break;
                            case '!':
                                instruction_add(POP, ebx, NULL, 0,0);
                                instruction_add(POP, eax, NULL, 0,0);
                                instruction_add(CMP, ebx, eax, 0,0);
                                instruction_add(SETNE, al, NULL, 0,0);
                                instruction_add(CBW, NULL, NULL, 0,0);
                                instruction_add(CWDE, NULL, NULL, 0,0);
                                instruction_add(PUSH, eax, NULL, 0,0);
                                break;
                        }
                    }
            }


            break;

        case VARIABLE:
            /*
             * Occurrences of variables: (declarations have their own case)
             * - Find the variable's stack offset
             * - If var is not local, unwind the stack to its correct base
             */

            //Finding the scope of the variable. If the difference is 0, it is
            //defined in this scope, if it is 1, the previous one and so on
            depth_difference = depth - root->entry->depth;

            //The offset of the variable is relative to its ebp. The current ebp is saved
            //on the stack, and the needed one retrived
            instruction_add(PUSH, ebp, NULL, 0,0);

            //The ebp points to the previous ebp, which points to the ebp before it and so on.
            //The ideal instruction to use would be 'movl (%ebp) %ebp', but that can't be done
            //with this framework. Rather than changing the framework, the following hack is used:
            //
            //The constant 4 and the contents of ebp is added and placed in eax, then the
            //the value pointed to by eax with an offset of -4, that is -4(%eax), is placed in ebp
            //since eax is ebp + 4, -4(%eax) is really (%ebp)
            for(int c = 0; c < depth_difference; c++){
                instruction_add(MOVE, STRDUP("$4"), eax, 0,0);
                instruction_add(ADD, ebp, eax, 0,0);
                instruction_add(MOVE, eax, ebp, -4,0);
            }

            //The offset of the vaiable (from its ebp)
            int32_t offset = root->entry->stack_offset;

            //The value of the variable is placed in eax, the right ebp is used, because of 
            //the system above
            instruction_add(MOVE, ebp, eax, offset, 0);

            //The current ebp is restored
            instruction_add(POP, ebp, NULL, 0,0);

            //The value of the variable is placed on the stack (since it's a kind of expression)
            instruction_add(PUSH, eax, NULL, 0,0);

            break;

        case INTEGER:
            /*
             * Integers: constants which can just be put on stack
             */

            //We can't have a label followed by a declaration, so this is needed...
            elegant_solution = 0;

            //The value of the integer is fetched and converted to a string
            char temp1[10]; //ints are 4 bytes, so this is enough
            int32_t t = *((int32_t*)root->data);
            sprintf(temp1, "%d", t);
            char temp2[11] = "$";
            strcat(temp2, temp1);

            //The value is pushed on the stack
            instruction_add(PUSH, STRDUP(temp2), NULL, 0,0);
            break;

        case ASSIGNMENT_STATEMENT:
            /*
             * Assignments:
             * Right hand side is an expression, find left hand side on stack
             * (unwinding if necessary)
             */

            //Generating the code for the expression part of the assingment. The result is
            //placed on the top of the stack
            generate(stream, root->children[1]);

            //Using same scheme as above
            depth_difference = depth - root->children[0]->entry->depth;

            instruction_add(PUSH, ebp, NULL, 0,0);
            for(int c = 0; c < depth_difference; c++){
                instruction_add(MOVE, STRDUP("$4"), eax, 0,0);
                instruction_add(ADD, ebp, eax, 0,0);
                instruction_add(MOVE, eax, ebp, -4,0);
            }

            int32_t offset_2 = root->children[0]->entry->stack_offset;

            //Putting the current ebp in ebx
            instruction_add(POP, ebx, NULL, 0,0);

            //Putting the result of the expression in eax
            instruction_add(POP, eax, NULL, 0,0);

            //Putting the result of the expression in the variable (ebp is the ebp of the variable)
            instruction_add(MOVE, eax, ebp, 0, offset_2);

            //Restoring the current ebp
            instruction_add(MOVE, ebx, ebp, 0, 0);
            break;

        case RETURN_STATEMENT:
            /*
             * Return statements:
             * Evaluate the expression and put it in EAX
             */
            RECUR();
            instruction_add(POP, eax, NULL, 0,0);

            for ( int u=0; u<depth-1; u++ ){
                instruction_add ( LEAVE, NULL, NULL, 0, 0 );
            }
            instruction_add ( RET, eax, NULL, 0, 0 );

            break;
            
        case WHILE_STATEMENT: {
				//Increment the number of while loops. 
				n_while++;
				
				//Create the start label for the while-loop.
				len = strlen(func_name);
				char start_label[100];
				snprintf(start_label, 100, "%s%s", func_name, "_while_");
				snprintf(start_label, 100, "%s%d", start_label, n_while);
				//Start label with added "_" for the jump.
				char jump_start_label[100];
				snprintf(jump_start_label, 100, "_%s", start_label);
				
				//End label
				char end_label[100];
				snprintf(end_label, 100, "%s%s", start_label, "_end");
				//End label with added "_" for the jump.
				char jump_end_label[100];
				snprintf(jump_end_label, 100, "_%s", end_label);
				
				instruction_add(LABEL, STRDUP(start_label), NULL, 0, 0);
				
				//Evaluate the expression
				generate(stream, root->children[0]);
				//Pop the result to eax
				instruction_add(POP, eax, NULL, 0, 0);
				//Compare and jump to end_label if eax equals zero.
				instruction_add(CMP, STRDUP("$0"), eax, 0, 0);
				instruction_add(JUMPEQ, STRDUP(jump_end_label), NULL, 0, 0);
				//Generate the statement instructions.
				generate(stream, root->children[1]);
				//Jump to start label
				instruction_add(JUMP, STRDUP(jump_start_label), NULL, 0, 0);
				//Add end label. 
				instruction_add(LABEL, STRDUP(end_label), NULL, 0, 0);
			}
            break;

        case FOR_STATEMENT: {
				//Increment the number of the for loop.
				n_for++;
				/** LABELS **/
				//Create the start label for the for loop. 
				len = strlen(func_name);
				char start_label[100];
				snprintf(start_label, 100, "%s%s", func_name, "_for_");
				snprintf(start_label, 100, "%s%d", STRDUP(start_label), n_for);
				//Create the jump label with "_" in front.
				char jump_start_label[100];
				snprintf(jump_start_label, 100, "_%s", start_label);
				//Create the end label if the condition is false.
				char end_label[100];
				snprintf(end_label, 100, "%s%s", start_label, "_end");
				//Create the jump end label, adding "_" in fron of end label.
				char jump_end_label[100];
				snprintf(jump_end_label, 100, "_%s", end_label);
				
				/** SET COUNTER TO START VALUE **/
				generate(stream, root->children[0]);
				
				
				/** START LABEL **/
				instruction_add(LABEL, STRDUP(start_label), NULL, 0, 0);
				
				//The nodes that represent the counter and the end value expression, respectively. 
				node_t *counter = root->children[0]->children[0];
				node_t *endValue = root->children[1];
				/** Test if counter >= endValue. If so, jump to end **/

				generate(stream, counter);
				generate(stream, endValue);
				instruction_add(POP, ebx, NULL, 0, 0);
				instruction_add(POP, eax, NULL, 0, 0);
				
				instruction_add(CMP, ebx, eax, 0,0);
                instruction_add(SETGE, al, NULL, 0,0);
                instruction_add(CBW, NULL, NULL, 0,0);
                instruction_add(CWDE, NULL, NULL, 0,0);
				instruction_add(CMP, STRDUP("$1"), eax, 0, 0);
				instruction_add(JUMPEQ, STRDUP(jump_end_label), NULL, 0, 0);
				//Loop-body
				generate(stream, root->children[2]);
				
				/**Increment counter **/
				depth_difference = depth - counter->entry->depth;

				instruction_add(PUSH, ebp, NULL, 0,0);
				for(int c = 0; c < depth_difference; c++){
					instruction_add(MOVE, STRDUP("$4"), eax, 0,0);
					instruction_add(ADD, ebp, eax, 0,0);
					instruction_add(MOVE, eax, ebp, -4,0);
				}

				int32_t offset_2 = counter->entry->stack_offset;

				//Putting the current ebp in ebx
				instruction_add(POP, ebx, NULL, 0,0);

				//Putting the result of the expression in the variable (ebp is the ebp of the variable)
				instruction_add(ADD, STRDUP("$1"), ebp, 0, offset_2);

				//Restoring the current ebp
				instruction_add(MOVE, ebx, ebp, 0, 0);
				
				/** Jump to begining **/
				instruction_add(JUMP, STRDUP(jump_start_label), NULL, 0, 0);
				
				//Add end label.
				instruction_add(LABEL, STRDUP(end_label), NULL, 0, 0);
				
				
				
			}
            break;
            
        case IF_STATEMENT: { 
				n_if = n_if+1;
        		len = strlen(func_name);
				//Label for the end of the if statement. 
				char end_label[100];
				snprintf(end_label, 100, "%s%s%d", func_name, "_endOfIf_", n_if);
				
				//Need to add "_" when jumping to label.
				char jump_end_label[100];
				snprintf(jump_end_label, 100, "_%s", end_label);
				
				if (root->n_children == 2) {
					//Evaluate expression and pop result to eax and check if zero.
					generate(stream, root->children[0]);
					instruction_add(POP, eax, NULL, 0, 0);
					instruction_add(CMP, STRDUP("$0"), eax, 0, 0);
					//Jump to end if expression is zero.
					instruction_add(JUMPEQ, STRDUP(jump_end_label), NULL, 0, 0);
					//Generate the statement
					generate(stream, root->children[1]);
					//Add end label.
					
				}
				else {
					//Else label
					char else_label[100];
					snprintf(else_label, 100, "%s%s%d", func_name, "_else_", n_if);
					//Evaluate expression and pop it to eax. Jmp if zero.
					generate(stream, root->children[0]);
					instruction_add(POP, eax, NULL, 0, 0);
					instruction_add(CMP, STRDUP("$0"), eax, 0, 0);
					//Need to add "_" before the label when jumping
					char jump_else_label[100];
					snprintf(jump_else_label, 100, "_%s", else_label);
					instruction_add(JUMPEQ, STRDUP(jump_else_label), NULL, 0, 0);
					//Execute the "true statement".
					generate(stream, root->children[1]);
					//Jump to end of the if-statement.
					instruction_add(JUMP, STRDUP(jump_end_label), NULL, 0, 0);
					//Add the else label.
					instruction_add(LABEL, STRDUP(else_label), NULL, 0, 0);
					//Execute the else statement.
					generate(stream, root->children[2]);
					
				}
				instruction_add(LABEL, STRDUP(end_label), NULL, 0, 0);
			}
            break;

        case NULL_STATEMENT:
        		RECUR();
            break;

        default:
            /* Everything else can just continue through the tree */
            RECUR();
            break;
    }
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
