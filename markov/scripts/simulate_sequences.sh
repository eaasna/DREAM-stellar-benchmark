#!/usr/bin/env bash
set -e

if [ "$#" -ne 8 ]; then
	echo "Usage: bash + 8 args"
fi

REF_IN=$1
REF_OUT=$2
QUERY_OUT=$3
REF_LENGTH=$4 	# 2^20 = 1Mb
QUERY_LENGTH=$5 	# 2^20 = 1Mb
REF_SEED=$6
QUERY_SEED=$7
ORDER=$8

execs=(markov_genome generate_local_matches)
for exec in "${execs[@]}"; do
    if ! which ${exec} &>/dev/null; then
        echo "${exec} is not available"
        echo ""
        echo "make sure \"${execs[@]}\" are reachable via the \${PATH} variable"
        echo ""

        # trying to do some guessing here:
        paths+=(/group/ag_abi/evelina/DREAM-stellar-benchmark/lib/raptor_data_simulation/build/bin)
        paths+=(./group/ag_abi/evelina/DREAM-stellar-benchmark/lib/raptor_data_simulation/build/src/mason2/src/mason2-build/bin)
	paths+=(/group/ag_abi/evelina/markov_genome/target/release)
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
len=$(( $REF_LENGTH / 5 ))
markov_genome simulate --seed $REF_SEED --order $ORDER --input $REF_IN --lens $len --lens $len --lens $len --lens $len --lens $len --output $REF_OUT

len=$(( $QUERY_LENGTH / 5 ))
echo "Simulating query of length $QUERY_LENGTH with seed $QUERY_SEED"
markov_genome simulate --seed $QUERY_SEED --order $ORDER --input $REF_IN --lens $len --lens $len --lens $len --lens $len --lens $len --output $QUERY_OUT

