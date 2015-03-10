#!/bin/bash
rm -rf testOutput
mkdir testOutput

for inputFile in `ls vsl_programs/*.vsl`; do
	echo "Testing $inputFile ..."
	inputFileBase=`basename $inputFile .vsl`
	./bin/vslc < $inputFile > testOutput/$inputFileBase.s
	gcc -m32 testOutput/$inputFileBase.s -o testOutput/a.out
	./testOutput/a.out > testOutput/$inputFileBase.result
	diff vsl_programs/$inputFileBase.output testOutput/$inputFileBase.result > testOutput/$inputFileBase.diff
	if [ ! -s "testOutput/$inputFileBase.diff" ]; then
		echo -e "\e[00;32mCorrect\e[00m"
		rm testOutput/$inputFileBase.*
	else
		echo -e "\e[00;31mERROR\e[00m"
	fi
	rm testOutput/a.out
	echo
done
