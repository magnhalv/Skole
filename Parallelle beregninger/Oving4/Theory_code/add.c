#include <stdio.h>
#include <omp.h>

int main(){
    int a[1000];
    for(int i = 0; i < 1000; i++){
        a[i] = i;
    }

    int sum = 0;
#pragma omp parallel for \ 
    reduction (+:sum)
    for(int i = 0; i < 1000; i++){
        sum += i;
    }


    printf("sum: %d\n", sum); // Should be 499500
}
