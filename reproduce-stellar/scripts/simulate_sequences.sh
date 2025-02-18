#!/usr/bin/env bash
set -e

REF_OUT=$1
QUERY_OUT=$2
REF_LENGTH=$3 	# 2^20 = 1Mb
QUERY_LENGTH=$4 	# 2^20 = 1Mb
REF_SEED=$5
QUERY_SEED=$6

execs=(mason_genome mason_variator generate_local_matches)
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

echo "Simulating reference of length $REF_LENGTH with seed $REF_SEED"
mason_genome -l $REF_LENGTH -o $REF_OUT -s $REF_SEED &> /dev/null

echo "Simulating query of length $QUERY_LENGTH with seed $QUERY_SEED"
mason_genome -l $QUERY_LENGTH -o $QUERY_OUT -s $QUERY_SEED &> /dev/null

