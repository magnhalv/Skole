CFLAGS = -I. -I/share/apps/atlas/include -std=c99 -O3 
LDFLAGS = -L/share/apps/atlas/lib 
LDLIBS = -latlas -lcblas -lm
all: gemm_naive gemm_atlas gemm_fast
	./gemm_fast 256 256 256
	./gemm_naive 256 256 256

gemm_naive : gemm.c naive.o
	gcc $(CFLAGS) $(LDFLAGS) gemm.c naive.o -o gemm_naive $(LDLIBS) 

gemm_atlas : gemm.c atlas.o
	gcc $(CFLAGS) $(LDFLAGS) gemm.c atlas.o -o gemm_atlas  $(LDLIBS)

gemm_fast : gemm.c fast.o
	gcc $(CFLAGS) $(LDFLAGS) -std=c99 -O3 -msse3 gemm.c fast.o -o gemm_fast $(LDLIBS)

%.o : %.c
	gcc $(CFLAGS) -msse3 -c $<

run:
	scp fast.c magnhalv@clustis3.idi.ntnu.no:~/Oving3/
	ssh magnhalv@clustis3.idi.ntnu.no 'cd ~/Oving3/;make all'

test: 
	scp simd.c magnhalv@clustis3.idi.ntnu.no:~/Oving3/
	ssh magnhalv@clustis3.idi.ntnu.no 'cd ~/Oving3/;gcc $(CFLAGS) $(LDFLAGS) -std=c99 -O3 -msse3 simd.c -o lol $(LDLIBS);./lol'
clean:
	rm gemm_* *.o
