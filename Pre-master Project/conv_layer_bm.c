#include <stdio.h>
#include <sys/time.h>
#include <math.h>


void print_table(double *table, int table_dim) {
    int i,j;
    for (i=0; i < table_dim; i++) {
        for (j=0; j < table_dim; j++) {
            printf("%f%s", *(table+j+i*table_dim), "-");
        }
        printf("\n");
    }
    printf("\n");
    
}

double sigmoid(double x) {
    return 1.0/(1.0+exp(-x)); 
}

int conv_layer(int i_dim, int k_dim) {

	   
    struct timeval stop, start;

	int img_dim = i_dim;
	int kernel_dim = k_dim;
	int fm_dim = img_dim-kernel_dim+1;
	int ss_dim = 2;
    int pooled_dim = fm_dim/ss_dim;

	double img[img_dim][img_dim], feature_map[fm_dim][fm_dim], kernel[kernel_dim][kernel_dim], pooled_map[pooled_dim][pooled_dim];

	int i, j, x, y;
	y, x = 0;
	for(i=0; i < img_dim; i++) {
		for (j=0; j < img_dim; j++) {
			img[i][j]=(rand()%10)/20.0;
		    if (i < kernel_dim && j < kernel_dim) {
			    kernel[i][j]=(rand()%10)/10.0;
			    x++;
		    }
	
        }
    }

    gettimeofday(&start, NULL);

	double sum;
	for (i = 0; i < fm_dim; i++) {
		for (j=0; j < fm_dim; j++) {
			sum = 0;
			for (y=0; y < kernel_dim; y++) {
				for (x=0; x < kernel_dim; x++) {
				    sum += img[i+y][j+x]*kernel[y][x];
                }
			}
            feature_map[i][j] = sigmoid(sum);
		}
	}
    
    for (i = 0; i < pooled_dim; i++) {
        for (j = 0; j < pooled_dim; j++) {
            double max = -1;
            for (y = 0; y < ss_dim; y++) { 
                for (x=0; x < ss_dim; x++) {
                    if (feature_map[i*ss_dim+y][j*ss_dim+x] > max) {
                        max = feature_map[i*ss_dim+y][j*ss_dim+x];
                    }     
                }
            }
            pooled_map[i][j]=max;
        }
    }

    
    
    gettimeofday(&stop, NULL);
    //print_table((double*)img, img_dim);
    //print_table((double*)kernel, kernel_dim);
    //print_table((double*)feature_map, fm_dim);    
    print_table((double*)pooled_map, pooled_dim);
	
    
    printf("%lu\n", stop.tv_usec - start.tv_usec);
    return stop.tv_usec - start.tv_usec;
}

int main () {
	struct timeval start, stop;
	srand(time(NULL)); 

	int total_time = 0;
	int nof_runs = 1000;
	int table[nof_runs];

	const int nof_imgs = 1;
	const int nof_kernels = 3;
	int img_dims[1] = {512};
	int kernel_dims[3] = {5, 7, 10};

	int results[3][1];


	for (int img = 0; img < nof_imgs; img++) {
		for (int kernel = 0; kernel < nof_kernels; kernel++) {
			total_time = 0;
			for (int i = 0; i < nof_runs; i++) {
				int time_used = conv_layer(img_dims[img], kernel_dims[kernel]);
				if (time_used > 0) {
					total_time += time_used;	
				}
			}
			results[kernel][img] = total_time/nof_runs;
		}
	}
    
    for (int kernel = 0; kernel < nof_kernels; kernel++) {
		printf("Results with %d sized kernel:\n", kernel_dims[kernel]);
		for (int img = 0; img < nof_imgs; img++) {
			printf("\t%d x %d: %d microseconds\n", img_dims[img], img_dims[img], results[kernel][img]);
		}
		printf("\n");
	}	
	/*
    printf("%s\n", "-----------------------");
	for (int i = 0; i < nof_runs; i++) {
		printf("%d\n", table[i]);
	}
    

	printf("Average used time is : %d microseconds.\n", total_time/nof_runs);
	*/
    return 0;
}
