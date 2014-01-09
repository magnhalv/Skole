VSLC=../bin/vslc
ASFLAGS=-32
LDFLAGS=-m32
SOURCES=$(shell ls *.vsl)
ASSEMBLY=$(subst .vsl,.s,${SOURCES})
TARGETS=${ASSEMBLY}
all: ${TARGETS}
test: all
	@echo "\n-- Testing the scanner with all things lexical:"
	./all_lexical
clean:
	@for FILE in ${ASSEMBLY}; do\
		if [ -e $$FILE ]; then \
			echo "Removing $$FILE" && rm $$FILE;\
		fi;\
	done
purge: clean
	@for FILE in ${TARGETS}; do\
		if [ -e $$FILE ]; then \
			echo "Removing $$FILE" && rm $$FILE;\
		fi;\
	done
%.s: %.vsl
	${VSLC} ${VSLFLAGS} -f $*.vsl -o $*.s
