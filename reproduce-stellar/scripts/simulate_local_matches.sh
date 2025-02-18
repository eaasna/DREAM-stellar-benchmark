#!/usr/bin/env bash
set -e

REP=$1 # gives a unique name to each output file
DIR=$2
MIN_LEN=$3
MAX_LEN=$4
REF_LEN=$5
ERROR_RATE=$6
MATCH_COUNT=$7
SEED=$8

echo "Sampling $MATCH_COUNT local matches between $MIN_LEN and $MAX_LEN bp with an error rate of $ERROR_RATE"

mkdir -p local_matches
mkdir -p query
generate_local_matches \
	--matches-out $DIR/local_matches/rep${REP}_e${ERROR_RATE}.fasta \
	--genome-out $DIR/query/rep${REP}_e${ERROR_RATE}.fasta \
	--max-error-rate $ERROR_RATE \
	--num-matches $MATCH_COUNT \
	--min-match-length $MIN_LEN \
	--max-match-length $MAX_LEN \
	--ref-len $REF_LEN \
	--verbose-ids \
	--query $DIR/random_rep${REP}.fasta \
	$DIR/ref_rep${REP}.fasta 1> $DIR/match_positions.txt 2> /dev/null


truth_file="${DIR}/ground_truth/rep${REP}_e${ERROR_RATE}.tsv"
grep ">" $DIR/local_matches/rep${REP}_e${ERROR_RATE}.fasta | cut -c 2- | awk -F, '{ print $1 " " $2 }' | sed 's/start_position=//g' | sed 's/length=//g' | awk '{print $2 "\t" $2+$3 }' > $truth_file
sort -g -k2 $truth_file -o $truth_file

