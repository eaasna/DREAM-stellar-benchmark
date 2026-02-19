#!/bin/bash

set -ex

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

###################################### data simulation #####################################

REF_IN="/bigdata/ag_abi/evelina/mouse/dna4.fasta"
ref_size="100Mb"

REF_LENGTH=104857600
QUERY_LENGTH=1048576

ORDER=11

MIN_LEN=50
MAX_LEN=200

MATCH_COUNT=104857

###################################### input parameters #####################################
reps=5

max_er=0.1
er_count=$1
p=50
er=$(bc <<< "scale=2;$er_count/$p")
ERROR_RATE="$er"

data_dir="/srv/data/evelina/markov/$ref_size"
DIR=$data_dir

mkdir -p local_matches
mkdir -p ref
	
for i in $(seq 1 $reps);do
	REF_OUT="$data_dir/large_rep${i}.fasta"
	QUERY_OUT="$data_dir/small_rep${i}.fasta"

	REF_SEED=$((i*12))
	QUERY_SEED=$((i*134))
	
	if [ ! -f $REF_OUT ]; then
		echo "Simulating reference of length $REF_LENGTH with seed $REF_SEED"
		len=$(( $REF_LENGTH / 10 ))
		markov_genome simulate --seed $REF_SEED --order $ORDER --input $REF_IN --lens $len --lens $len --lens $len --lens $len --lens $len --lens $len --lens $len --lens $len --lens $len --lens $len --output $REF_OUT
	fi
	
	if [ ! -f $QUERY_OUT ]; then 
		echo "Simulating query of length $QUERY_LENGTH with seed $QUERY_SEED"
		len=$(( $QUERY_LENGTH / 10 ))
		markov_genome simulate --seed $QUERY_SEED --order $ORDER --input $REF_IN --lens $len --lens $len --lens $len --lens $len --lens $len --lens $len --lens $len --lens $len --lens $len --lens $len --output $QUERY_OUT
	fi

	echo "Sampling $MATCH_COUNT local matches between $MIN_LEN and $MAX_LEN bp with an error rate of $ERROR_RATE"
	generate_local_matches \
		--matches-out $DIR/local_matches/rep${i}_e0${ERROR_RATE}.fasta \
		--genome-out $DIR/ref/rep${i}_e0${ERROR_RATE}.fasta \
		--max-error-rate $ERROR_RATE \
		--num-matches $MATCH_COUNT \
		--min-match-length $MIN_LEN \
		--max-match-length $MAX_LEN \
		--ref-len $QUERY_LENGTH \
		--verbose-ids \
		--normal \
		--seed $QUERY_SEED \
		--query $DIR/large_rep${i}.fasta \
		$DIR/small_rep${i}.fasta 1> $DIR/match_positions.txt
		#2> /dev/null

	truth_file="${DIR}/ground_truth/rep${i}_e${ERROR_RATE}.tsv"
	grep ">" $DIR/local_matches/rep${i}_e0${ERROR_RATE}.fasta | cut -c 2- | awk -F, '{ print $1 " " $2 }' | sed 's/start_position=//g' | sed 's/length=//g' | awk '{print $2 "\t" $2+$3 }' > $truth_file
	sort -g -k2 $truth_file -o $truth_file
done

