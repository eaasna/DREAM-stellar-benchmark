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
evaluate --truth $truth --test ${id}_l${min_len}_e${er}_simple.gff --ref-meta /group/ag_abi/evelina/DREAM-stellar-benchmark/genome-wise/human/dream/meta/b2048_fpr0.005_l100_e1.bin --overlap 1 --min-len 50 &> /dev/null

total_var_count=$(grep -v '#' $truth | wc -l | awk '{print $1}')
tp_var_count=$(wc -l ${id}_l${min_len}_e${er}_simple.tp.bed | awk '{print $1}')
fp_var_count=$(awk -v p="$precision" '{print $4 + p}' ${id}_l${min_len}_e${er}_simple.fp.gff | rev | cut -c$pn- | rev | sort | uniq | wc -l | awk '{print $1 }')

echo $id
echo "Total variants $total_var_count"
echo "True positive variants $tp_var_count"
echo "False positive variants $fp_var_count (precision $precision)"
frac_new=$(bc <<< "scale=3; $fp_var_count/($tp_var_count+$fp_var_count)")
echo "Fraction of new variants $frac_new"

