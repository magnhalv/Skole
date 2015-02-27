CC=gcc
CFLAGS=-std=c99 -g
SOURCES= tests/convolution_layer_test.c src/*.c

run_gdb: test
	gdb ./cl_test

run_tests: test
	./cl_test

test:
	$(CC) $(CFLAGS) $(SOURCES) -o cl_test
