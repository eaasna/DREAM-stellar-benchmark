#!/bin/bash

set -e

if [[ "$#" -ne 4 ]]; then
	echo "Usage: bash evaluate_accuracy.sh <min len> <error rate> <id> <precision>"
	exit
fi

dir="/buffer/ag_abi/evelina/1000genomes/phase2/ftp.sra.ebi.ac.uk/vol1/run"
cd $dir

min_len=$1
er=$2
id=$3
precision=$4
rounder=$(bc <<< $precision/2)
pn=${#precision}

truth="../../../freeze3.sv.alt.meta.bed"

for test_type in "read_range" "var"; do
	echo -e "$id\t$test_type"
	evaluate --ignore-query --ignore-strand --truth $truth --test ${id}_l${min_len}_e${er}_${test_type}.gff --ref-meta /group/ag_abi/evelina/DREAM-stellar-benchmark/genome-wise/human/dream/meta/b2048_fpr0.005_l100_e1.bin --overlap 1 --min-len 50 &> /dev/null

	total_var_count=$(grep -v '#' $truth | wc -l | awk '{print $1}')
	tp_var_count=$(wc -l ${id}_l${min_len}_e${er}_${test_type}.tp.bed | awk '{print $1}')

	fp_file="${id}_l${min_len}_e${er}_${test_type}.fp.gff"
	if [ "$test_type" == "read_range" ]; then
		while read match; do
        		qstart=$(echo $match | awk '{print $9}'  | awk -F';' '{print $2}' | sed 's/seq2Range=//g' | awk -F',' '{print $1}')
        		qend=$(echo $match | awk '{print $9}'  | awk -F';' '{print $2}' | sed 's/seq2Range=//g' | awk -F',' '{print $2}') 
        		qid=$(echo $match | awk '{print $9}' | awk -F';' '{print $1}')
			qlen=$(echo $match | awk '{print $9}' | awk -F';' '{print $6}' | sed 's/qlen=//g' | awk '{print $2}' )
        		qoffset=$(bc <<< $qlen-$qend)

			# convert back to exact var position
        		echo $match | awk -v qs="$qstart" -v qo="$qoffset" '{print $1 "\t" $2 "\t" $3 "\t" $4+qs "\t" $5-qo "\t" $6 "\t" $7 "\t" $8 "\t" $9}' >> $fp_file.tmp
		done < $fp_file
		mv $fp_file.tmp $fp_file
	fi

	fp_var_count=$(awk -v r="$rounder" '{print $1 "\t" $4 + r}' $fp_file | rev | cut -c$pn- | rev | sort | uniq | wc -l | awk '{print $1 }')

	echo "Total variants $total_var_count"
	echo "True positive variants $tp_var_count"
	echo "False positive variants $fp_var_count (precision $precision)"
	frac_new=$(bc <<< "scale=3; $fp_var_count/($tp_var_count+$fp_var_count)")
	echo "Fraction of new variants $frac_new"
done
