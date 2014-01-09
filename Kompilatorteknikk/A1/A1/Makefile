CFLAGS+= -std=c99 -Wall

objects = rpn.o main.o

all : rpn

test : all
	@echo ""
	@echo "Testing..."
	@echo ""
	@echo "Should be 10..."
	./rpn < 10.txt
	@echo ""
	@echo "Should be 100..."
	./rpn < 100.txt
	@echo ""
	@echo "Should be 1000..."
	./rpn < 1000.txt

rpn : $(objects)
	gcc $(objects) -o rpn
	
.PHONY : clean purge

clean :
	rm -f rpn.o main.o
	
purge :
	rm -f rpn.o main.o rpn
