#include "rpn.h"

RpnCalc newRpnCalc(){
    RpnCalc rpnCalc;
    rpnCalc.capacity = 1;
    rpnCalc.size = 0;
    rpnCalc.stack = (double*) malloc(sizeof(double)*1);
    return rpnCalc;
}

void push(RpnCalc* rpnCalc, double n){

    if ((rpnCalc->size + 1) == rpnCalc->capacity) {
        rpnCalc->capacity = rpnCalc->capacity*2;
        rpnCalc->stack = realloc(rpnCalc->stack, sizeof(double) * rpnCalc->capacity);
    }
    //printf("size: ");
    //printf("%i\n", rpnCalc->size);
    rpnCalc->size++;
    rpnCalc->stack[rpnCalc->size-1] = n;
}

void performOp(RpnCalc* rpnCalc, char op){
    double first = rpnCalc->stack[rpnCalc->size-2];
    double second = rpnCalc->stack[rpnCalc->size-1];
    rpnCalc->size = rpnCalc->size - 2;
    if (op == '+') push(rpnCalc, first+second);
    else if (op == '-') push(rpnCalc, first-second);
    else if (op == '/') push(rpnCalc, first/second);
    else if (op == '*') push(rpnCalc, first*second);
    //printf("NewValue: ");
    //printf("%f\n", peek(rpnCalc));
    //printf("size: ");
    //printf("%i\n", rpnCalc->size);

}

double peek(RpnCalc* rpnCalc){
    return rpnCalc->stack[rpnCalc->size-1];
}
