#!/bin/bash

set -e

if [[ "$#" -ne 1 ]]; then
	echo "Usage: bash make_read_range.sh <id>"
	exit
fi

dir="/buffer/ag_abi/evelina/1000genomes/phase2/ftp.sra.ebi.ac.uk/vol1/run"
cd $dir

id=$1
reads="$id.unmapped.fa"
len_out="$id.lens.tsv"

grep ">" $reads | sed 's/>//g' | sort | uniq > ids.tmp

if [ -f $len_out ];then 
	rm $len_out
fi

while read id; do
	len=$(grep $id -A 1 $reads | tail -n 1 | wc -c | awk '{print}')
	echo -e "$id\t$len" >> $len_out
done < ids.tmp


rm ids.tmp

