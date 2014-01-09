#!/bin/bash
rm -rf testOutput
mkdir testOutput
for inputFile in `ls vsl_programs/*.vsl`; do
	echo "Testing $inputFile ..."
	inputFileBase=`basename $inputFile .vsl`
	./bin/vslc < $inputFile 2> testOutput/$inputFileBase.out
	diff vsl_programs/$inputFileBase.simpletree testOutput/$inputFileBase.out > testOutput/$inputFileBase.diff
	if [ ! -s "testOutput/$inputFileBase.diff" ]; then
		echo -e "\e[00;32mCorrect\e[00m"
		rm testOutput/$inputFileBase.*
	else
		echo -e "\e[00;31mERROR\e[00m"
	fi
	echo
done
