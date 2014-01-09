#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define SIZE 1000000

typedef struct{
    double a;
    double b;
    double c;
    double d;
    double e;
    double f;
    double g;
    double h;
} Doubles;

double array_of_structs(){
    Doubles* d = (Doubles*)malloc(sizeof(Doubles) * SIZE);
    for(int i = 0; i < SIZE; i++){
        d[i].a = ((double)rand())/((double)RAND_MAX);
        d[i].b = ((double)rand())/((double)RAND_MAX);
        d[i].c = ((double)rand())/((double)RAND_MAX);
        d[i].d = ((double)rand())/((double)RAND_MAX);
        d[i].e = ((double)rand())/((double)RAND_MAX);
        d[i].f = ((double)rand())/((double)RAND_MAX);
        d[i].g = ((double)rand())/((double)RAND_MAX);
        d[i].h = ((double)rand())/((double)RAND_MAX);
    }

    double sum = 0;

    for(int j = 0; j < 100; j++){
        for(int i = 0; i < SIZE; i++){
            double temp_sum = 0;

            temp_sum += d[i].a;
            temp_sum += d[i].b;
            temp_sum += d[i].c;
            temp_sum += d[i].d;
            temp_sum += d[i].e;
            temp_sum += d[i].f;
            temp_sum += d[i].g;
            temp_sum += d[i].h;

            temp_sum /= (temp_sum + 1);

            d[i].a *= temp_sum;
            d[i].b *= temp_sum;
            d[i].c *= temp_sum;
            d[i].d *= temp_sum;
            d[i].e *= temp_sum;
            d[i].f *= temp_sum;
            d[i].g *= temp_sum;
            d[i].h *= temp_sum;

            temp_sum += d[i].a;
            temp_sum += d[i].b;
            temp_sum += d[i].c;
            temp_sum += d[i].d;
            temp_sum += d[i].e;
            temp_sum += d[i].f;
            temp_sum += d[i].g;
            temp_sum += d[i].h;

            sum += temp_sum;
        }
    }

    return sum;
}

double struct_of_arrays(){
    double* a = (double*)malloc(sizeof(double) * SIZE);
    double* b = (double*)malloc(sizeof(double) * SIZE);
    double* c = (double*)malloc(sizeof(double) * SIZE);
    double* d = (double*)malloc(sizeof(double) * SIZE);
    double* e = (double*)malloc(sizeof(double) * SIZE);
    double* f = (double*)malloc(sizeof(double) * SIZE);
    double* g = (double*)malloc(sizeof(double) * SIZE);
    double* h = (double*)malloc(sizeof(double) * SIZE);

    for(int i = 0; i < SIZE; i++){
        a[i] = ((double)rand())/((double)RAND_MAX);
        b[i] = ((double)rand())/((double)RAND_MAX);
        c[i] = ((double)rand())/((double)RAND_MAX);
        d[i] = ((double)rand())/((double)RAND_MAX);
        e[i] = ((double)rand())/((double)RAND_MAX);
        f[i] = ((double)rand())/((double)RAND_MAX);
        g[i] = ((double)rand())/((double)RAND_MAX);
        h[i] = ((double)rand())/((double)RAND_MAX);
    }

    double sum = 0;
    
    for(int j = 0; j < 100; j++){
        for(int i = 0; i < SIZE; i++){
            double temp_sum = 0;

            temp_sum += a[i];
            temp_sum += b[i];
            temp_sum += c[i];
            temp_sum += d[i];
            temp_sum += e[i];
            temp_sum += f[i];
            temp_sum += g[i];
            temp_sum += h[i];

            temp_sum /= (temp_sum + 1);

            a[i] *= temp_sum;
            b[i] *= temp_sum;
            c[i] *= temp_sum;
            d[i] *= temp_sum;
            e[i] *= temp_sum;
            f[i] *= temp_sum;
            g[i] *= temp_sum;
            h[i] *= temp_sum;

            temp_sum += a[i];
            temp_sum += b[i];
            temp_sum += c[i];
            temp_sum += d[i];
            temp_sum += e[i];
            temp_sum += f[i];
            temp_sum += g[i];
            temp_sum += h[i];

            sum += temp_sum;
        }
    }

    return sum;
}

int main(int argc, char** argv){
    printf("Starting...\n");

    // Test one function by commenting out the other
    //double result = array_of_structs();
    double result = array_of_structs();

    printf("Result: %f\n", result);

    printf("Done\n");
}

