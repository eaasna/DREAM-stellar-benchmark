#!/bin/bash

if [[ "$#" -ne 6 ]]; then
	echo "Usage: bash search_accuracy.sh <truth_file> <match_file> <min_len> <min_overlap> <meta> <out>"
	exit 1
fi

TRUTH=${1}
MATCHES=${2}

MIN_LENGTH=${3}
MIN_OVERLAP=${4}
META=${5}
OUT=${6}
eval_log=${MATCHES}.evaluation.log

evaluate=/group/ag_abi/evelina/evaluate-alignments/build/evaluate
$evaluate --truth $TRUTH --test $MATCHES --min-len $MIN_LENGTH --overlap $MIN_OVERLAP --ref-meta $META --verbose 2> $eval_log

total_match_count=$(wc -l "$TRUTH" | awk '{ print $1 }')
true_match_count=$(grep "True positives" $eval_log | awk '{print $3}')
missed_match_count=$(grep "False negatives" $eval_log | awk '{print $3}')
missed=$(bc <<< "scale=3; $missed_match_count/$total_match_count")


repeat_queries=0
repeat_lookups=0
if grep -q Insufficient $MATCHES.err
then
	repeat_queries=$(grep Insufficient $MATCHES.err | wc -l | awk '{print $1}')
	repeat_lookups=$(grep Insufficient $MATCHES.err | awk '{print $4}' | paste -sd+ | bc)
fi

echo -e 'total_match_count\ttrue_match_count\tmissed\trepeat_queries\trepeat_lookups' >> $OUT
echo -e "$total_match_count\t$true_match_count\t$missed\t$repeat_queries\t$repeat_lookups" >> $OUT

