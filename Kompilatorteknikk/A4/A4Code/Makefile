#
# Tools: We want the flex/bison implementations of lex/yacc
#
LEX=$(shell which flex)
YACC=$(shell which bison)

#
# Variables to control the various tools
# CFLAGS go to cc
# LDFLAGS and LDLIBS go to the linker (passed through cc)
# YFLAGS go to yacc
#

INCLUDEPATH=\
    -Iinclude\
    -I/usr/local/include\

CFLAGS+=  -D_POSIX_C_SOURCE -DDUMP_SYMTAB -std=c99 ${INCLUDEPATH}
LDFLAGS+= -L/usr/local/lib -Llib
LDLIBS+=  -lghthash
YFLAGS+=  --defines=work/parser.h -o y.tab.c

# Targets:

# Do everything by default, if it isn't done already
all: bin/vslc
test: all
	./test_runner.sh

vsl_programs/%: all vsl_programs/%.vsl
	${MAKE} -C vsl_programs $*

#
# The binary is built in 'obj' when all the object code is ready.
# Make a copy of it in 'bin', to leave it around even after cleanup of
# everything intermediate (i.e. the 'clean' target).
#
bin/vslc: obj/vslc $(filter-out $(wildcard bin), bin)
	cp obj/vslc bin/vslc

#
# The compiler executable depends on everything having turned into object code
#
obj/vslc: work/scanner.o work/parser.o obj/vslc.o obj/nodetypes.o obj/tree.o obj/symtab.o src/simplify.o

#
# For all the handwritten C files, there is a C file in 'src' and a matching
# header file in 'include', object code should be rebuilt every time there is
# a change in one or both.
# The dependency of src/*.o on src/*.c is implicit, dependency on the header
# file is included here.
# The code is built in 'src', and moved to 'obj' afterwards to keep the file
# tree tidy.
#
obj/%.o: src/%.o include/%.h $(filter-out $(wildcard obj), obj)
	mv src/$*.o obj/

#
# Generated C-files are likewise created in 'src', and moved to 'work'.
#
work/%.c: src/%.c $(filter-out $(wildcard work), work)
	mv src/$*.c work/

#
# Unusual sequential dependencies: the scanner cannot be compiled to object
# code before the header file from the parser exists, and the header file is
# created as a side-effect of creating the parser...
#
work/scanner.o: work/parser.h
work/parser.h: work/parser.c

#
# Cleanup.
#
clean:
	if [ -e work ]; then rm -r work; fi
	if [ -e obj ]; then rm -r obj; fi
	${MAKE} -C vsl_programs clean
purge: clean
	if [ -e bin ]; then rm -r bin; fi
	if [ -e testOutput ]; then rm -r testOutput; fi
	${MAKE} -C vsl_programs purge

#
# Targets to create directories (when they don't exist already).
#
work:
	mkdir work
obj:
	mkdir obj
bin:
	mkdir bin
