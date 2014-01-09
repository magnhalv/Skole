#include <stdlib.h>
#include <stdio.h>


typedef struct linked_list{
    struct linked_list* next;
    struct linked_list* prev;
    int value;
} linked_list;


void print_array_stats(double* array, int size){
	double sum = array[0];
	double max = array[0];
	int i;
	for (i = 1; i<size; i++) {
		sum += array[i];
		if (array[i] > max) {
			max = array[i];
		}
	}
	printf("Sum: %f\n", sum);
	printf("Max: %f\n", max);
	printf("Average: %f\n", sum/size);
}


linked_list* new_linked_list(int size, int value){
	linked_list* first = (linked_list*)malloc(sizeof(linked_list));
	first->value = value;
	first->prev = NULL;
	linked_list* last = first;
	int i;
	for (i = 1; i < size; i++) {
		linked_list* new = (linked_list*)malloc(sizeof(linked_list));
		new->value = value;
		new->prev = last;
		last->next = new;
		last = new;
	}
	last->next = NULL;
	return first;
	
}


void print_linked_list(linked_list* ll, int horizontal, int direction){
	if (ll == NULL) {
		printf("\n");
		return;
	}
	
	if (direction == 0) {
		while (ll->next != NULL) {
			ll = ll->next;
		}
		direction = -1;
	}
	if (horizontal == 1) printf("%d ", ll->value);
	else printf("%d\n", ll->value);

	if (direction == 1)print_linked_list(ll->next, horizontal, direction);
	else print_linked_list(ll->prev, horizontal, direction);
		
}


int sum_linked_list(linked_list* ll){
	int sum = 0;
	while (ll != NULL) {
		sum += ll->value;
		ll = ll->next;
	}
	return sum;
}


void insert_linked_list(linked_list* ll, int pos, int value){
	int i = 0;
	while(i < pos) {
		ll = ll->next;
		i++;
	}
	linked_list* new_node = (linked_list*)malloc(sizeof(linked_list));
	new_node->next = ll;
	new_node->prev = ll->prev;
	new_node->value = value;
	(ll->prev)->next = new_node;
	ll->prev = new_node;
}


void merge_linked_list(linked_list* a, linked_list* b){
	
	linked_list* next_a;
	linked_list* next_b;
	while (a->next != NULL) {
		next_a = a->next;
		next_b = b->next;
		a->next = b;
		b->prev = a;
		b->next = next_a;
		next_a->prev = b;
		a = next_a;
		b = next_b;
	}
	a->next = b;
	b->prev = a;
	
}

void destroy_linked_list(linked_list* ll){
	if (ll->next != NULL) destroy_linked_list(ll->next);
	free(ll);
	ll = NULL;
}

    


int main(int argc, char** argv){

    //Array statistics
    double array[5] = {2.0, 3.89, -3.94, 10.1, 0.88};

    print_array_stats(array, 5);
    //Creating liked list with 3 3s and 4 4s
	
    linked_list* ll3 = new_linked_list(3,3);
    linked_list* ll4 = new_linked_list(4,4);
	
    //Should print: "3 3 3"
	
    print_linked_list(ll3, 1, 1);
	
    //Inserting a 5 at the 1st position
    insert_linked_list(ll3, 1, 5);

    //Should print "3 5 3 3"
    print_linked_list(ll3, 1, 1);

    //Printing backwards, should print: "3 3 5 3"
    print_linked_list(ll3, 1, 0);

    //Merging the linked lists
    merge_linked_list(ll3, ll4);

    //Printing the result, should print: "3 4 5 4 3 4 3 4"
    print_linked_list(ll3, 1,1);

    //Summing the elements, should be 30
    printf("Sum: %d\n", sum_linked_list(ll3));

    //Freeing the memory of ll3
    destroy_linked_list(ll3);
}
