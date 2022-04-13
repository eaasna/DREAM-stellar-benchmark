#!/usr/bin/env bash
set -e

# NB: this assumes that the query file contains one long sequence

SEG_FILE=$1
QUERY_FILE=$2
OUT_FILE=$3

echo "Splitting $QUERY_FILE into partially overlapping segments"

query_id=$(head -n 1 $QUERY_FILE) # id line
query_id="${query_id:1}"
cnt=0
while read -r ind chr_id start length; do 
  end=$((start + length))
  # echo "Create segment with start: $start and length: $length and end: $end"
  printf ">${query_id}_${cnt} start_position=$start,length=$length\n"
  tail -n +2 $QUERY_FILE | dd bs=1 skip="$start" count="$length" status=none
  printf "\n"
  let cnt=cnt+1
done <$SEG_FILE >$OUT_FILE

