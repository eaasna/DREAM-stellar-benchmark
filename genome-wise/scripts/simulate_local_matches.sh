#!/usr/bin/env bash
set -e

BINARY_DIR="../../lib/raptor_data_simulation/build/bin"
REP=$1 # gives a unique name to each output file
ERROR_RATE=$2
MATCH_COUNT=$3
MIN_LEN=$4
MAX_LEN=$5
REF_LEN=$6

echo "Sampling $MATCH_COUNT local matches between $MIN_LEN and $MAX_LEN bp with an error rate of $ERROR_RATE"

match_dir=local_matches_e$ERROR_RATE\_rep$REP
mkdir -p $match_dir
$BINARY_DIR/generate_local_matches \
	--output $match_dir \
	--max-error-rate $ERROR_RATE \
	--num-matches $MATCH_COUNT \
	--min-match-length $MIN_LEN \
	--max-match-length $MAX_LEN \
	--ref-len $REF_LEN \
	--verbose-ids \
	ref_rep$REP.fasta 
	#&> /dev/null

mv $match_dir/ref_rep$REP.fastq local_matches/rep$REP\_e$ERROR_RATE.fastq
rm -r $match_dir