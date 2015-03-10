#include <stdio.h>
#include <pthread.h>

	int counter = 0;
	pthread_mutex_t mutex;
	pthread_cond_t cond_var;

void* run_thread(void* arg){
	printf("Thread %ld\n", (long)arg);
	
	pthread_mutex_lock(&mutex);
    counter++;
    if(counter == 5){
    	counter = 0;
    pthread_cond_broadcast(&cond_var);
    } else{
    while(pthread_cond_wait(&cond_var, &mutex)!=0);
    }
    pthread_mutex_unlock(&mutex);

	pthread_exit(NULL);
}
int main(){
	pthread_t threads[4];
	for (int j = 0; j < 5; j++) {
		for(long i = 0; i < 4; i++){
		pthread_create(&threads[i], NULL,
		run_thread, (void*)i);
		}
	
		pthread_mutex_lock(&mutex);
	    counter++;
	    if(counter == 5){
	    	counter = 0;
	    pthread_cond_broadcast(&cond_var);
	    } else{
	    while(pthread_cond_wait(&cond_var, &mutex)!=0);
	    }
	    pthread_mutex_unlock(&mutex);


	}
	pthread_exit(NULL);

}