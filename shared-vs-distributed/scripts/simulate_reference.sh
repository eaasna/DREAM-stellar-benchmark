#!/usr/bin/env bash
set -e

execs=(mason_genome generate_local_matches)
for exec in "${execs[@]}"; do
    if ! which ${exec} &>/dev/null; then
        echo "${exec} is not available"
        echo ""
        echo "make sure \"${execs[@]}\" are reachable via the \${PATH} variable"
        echo ""

        # trying to do some guessing here:
        paths+=(../../lib/raptor_data_simulation/build/bin)
        paths+=(../../lib/raptor_data_simulation/build/src/mason2/src/mason2-build/bin)

        p=""
        for pp in ${paths[@]}; do
            p=${p}$(realpath -m $pp):
        done    
        echo "you could try "
        echo "export PATH=${p}\${PATH}"

        exit 127
    fi      
done    

REF_LENGTH=$1 	# 2^20 = 1Mb
REF_SEED=$2
CHR_SIZE_BOUND=300000000

if [ $REF_LENGTH -gt $CHR_SIZE_BOUND ]
then 
	echo "Simulating random genome with chromosomes equal to "
	mason_genome -l 248956422 -l 242193529 -l 198295559 -l 190214555 -l 181538259 -l 170805979 -l 159345973 -l 145138636 -l 138394717 -l 133797422 -l 135086622 -l 133275309 -l 114364328 -l 107043718 -l 101991189 -l 90338345 -l 83257441 -l 80373285 -l 58617616 -l 64444167 -l 46709983 -l 50818468 -l 156040895 -l 57227415 -o ref.fasta -s $REF_SEED
fi


if [ $REF_LENGTH -le $CHR_SIZE_BOUND ]
then 
	echo "Simulating reference of length $REF_LENGTH with seed $REF_SEED"
	mason_genome -l $REF_LENGTH -o ref.fasta -s $REF_SEED
fi
