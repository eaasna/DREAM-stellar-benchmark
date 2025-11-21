#!/usr/bin/env bash
set -e

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
        paths+=(../../lib/raptor_data_simulation/build/bin)
        paths+=(../../lib/raptor_data_simulation/build/src/mason2/src/mason2-build/bin)
	paths+=(../../../markov_genome/target/release)
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
markov_genome simulate --seed $REF_SEED --order $ORDER --input $REF_IN --lens $REF_LEN --output $REF_OUT

echo "Simulating query of length $QUERY_LENGTH with seed $QUERY_SEED"
markov_genome simulate --seed $QUERY_SEED --order $ORDER --input $QUERY_IN --lens $QUERY_LEN --output $QUERY_OUT

