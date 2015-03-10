#ifndef RPN
#define RPN

typedef struct{
    int size;
    int capacity;
    double* stack;
} RpnCalc;

RpnCalc newRpnCalc();
void push(RpnCalc* rpnCalc, double n);
void performOp(RpnCalc* rpnCalc, char op);
double peek(RpnCalc* rpnCalc);

#endif
