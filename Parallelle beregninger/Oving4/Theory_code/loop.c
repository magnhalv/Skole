#include <stdio.h>
#include <omp.h>

int list[20] = {2,4,3,1,1,7,8,8,2,1,2,4,3,1,1,7,8,9,2,3};
int index = 0;
int found = 0;

int main(){

#pragma omp parallel
    while(1){

        int my_index;
#pragma omp critical
        {
        my_index = index;
        index++;
        }

        if(my_index >= 20){
            continue;
        }

        if(list[my_index] == 9){
            found = 1;
            printf("Found 9 at %d\n", my_index);
        }

        printf("Thread: %d, my_index: %d\n", omp_get_thread_num(), my_index);
        if (found == 1) break;
#pragma omp barrier
    }
    printf("Done\n");
}
    
