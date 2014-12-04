#include <stdio.h>
#include <sys/time.h>



void print_table(int *table, int table_dim) {
    int i,j;
    for (i=0; i < table_dim; i++) {
        for (j=0; j < table_dim; j++) {
            printf("%d%s", *(table+j+i*table_dim), "-");
        }
        printf("\n");
    }
    printf("\n");
    
}


int main () {
	
    struct timeval stop, start;

	int img_dim = 512;
	int kernel_dim = 7;
	int fm_dim = img_dim-kernel_dim+1;
	int pooled_dim = fm_dim/2;

	int img[img_dim][img_dim], feature_map[fm_dim][fm_dim], kernel[kernel_dim][kernel_dim], pooled_map[pooled_dim][pooled_dim];

	int i, j, x, y;
	y, x = 0;
	for(i=0; i < img_dim; i++) {
		for (j=0; j < img_dim; j++) {
			img[i][j]=j+i*img_dim+1;
		    if (i < kernel_dim && j < kernel_dim) {
			    kernel[i][j]=x;
			    x++;
		    }
	
        }
    }

    gettimeofday(&start, NULL);

	int sum;
	for (i = 0; i < fm_dim; i++) {
		for (j=0; j < fm_dim; j++) {
			sum = 0;
			for (y=0; y < kernel_dim; y++) {
				for (x=0; x < kernel_dim; x++) {
				    sum += img[i+y][j+x]*kernel[y][x];
                }
			}
            feature_map[i][j] = sum;
		}
	}

    gettimeofday(&stop, NULL);
    
    printf("Took %lu\n", stop.tv_usec - start.tv_usec);
    
    //print_table((int*)img, img_dim);
    //print_table((int*)kernel, kernel_dim);
    //print_table((int*)feature_map, fm_dim);    
	return 0;
}
