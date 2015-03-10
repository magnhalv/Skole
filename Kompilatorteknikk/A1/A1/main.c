#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "rpn.h"


// Global variables
char buffer[100];       // Buffer for one token
int bufferLength = 0;   // Length of current token

RpnCalc rpnCalc;         // RPN calculator


// Handle single token
void handleToken(){
    // Add NULL to end of token to make it a string
    buffer[bufferLength] = '\0';

    // Check if it is operator or number
    if(strpbrk(buffer, "+-*/") != NULL && strlen(buffer) == 1){
        // Operator
        performOp(&rpnCalc, *buffer);
    }
    else{
        // Number. Convert string to double, and push
        push(&rpnCalc, atof(buffer));
    }

    // Reset buffer
    bufferLength = 0;
}


// Handle single char from input
void handleChar(char c){
    if(c == ' ' || c == '\n'){
        if(bufferLength > 0){
            // A space or newline, and not empyt buffer, so a new token is ready
            handleToken();
        }
    }
    else{
        // Not space or newline, we add it to the current token
        buffer[bufferLength] = c;
        bufferLength++;
    }
}


int main(int argc, char** argv){

    // Initialize RPN calculator
    rpnCalc = newRpnCalc();
    // Read from standard input, one char at a time, and handle them
    int c = getchar();
    while(!feof(stdin)){

        handleChar(c);
        c = getchar();
    }

    // Print result (last element on stack)
    printf("%f\n", peek(&rpnCalc));
}
