#!/bin/bash

set -e

if [[ "$#" -ne 4 ]]; then
	echo "Usage: bash convert_valik_gff.sh <min len> <error rate> <id>"
	exit
fi

l=$1
e=$2
id=$3

dir="/buffer/ag_abi/evelina/1000genomes/phase2/ftp.sra.ebi.ac.uk/vol1/run"
cd $dir
work_dir="/group/ag_abi/evelina/DREAM-stellar-benchmark/structural-variants"

is_female=0
if [ $id = "HG00732" ]; then
	is_female=1
fi
if [ $id = "NA19238" ]; then
	is_female=1
fi

in="${id}_l${l}_e${e}.gff"
range_out="${id}_l${l}_e${e}_read_range.gff"
var_out="${id}_l${l}_e${e}_var.gff"
	
while read match; do
	qstart=$(echo $match | awk '{print $9}'  | awk -F';' '{print $2}' | sed 's/seq2Range=//g' | awk -F',' '{print $1}')
	qend=$(echo $match | awk '{print $9}'  | awk -F';' '{print $2}' | sed 's/seq2Range=//g' | awk -F',' '{print $2}')
	qid=$(echo $match | awk '{print $9}' | awk -F';' '{print $1}')
	qlen=$(grep $qid $id.lens.tsv | awk '{print $1}')
	qoffset=$(bc <<< $qlen-$qend)
	
	echo $match | awk -v qs="$qstart" -v qo="$qoffset" -v ql="$qlen" '{print $1 "\t" $2 "\t" $3 "\t" $4-qs "\t" $5+qo "\t" $6 "\t" $7 "\t" $8 "\t" $9 ";qlen=" ql}' >> $range_out.tmp
done < $in

if [ -f $range_out ]; then
	rm $range_out
fi

if [ -f $var_out ]; then
	rm $var_out
fi

while read chr; do
	if [ $is_female -eq 1 ]; then
		if [ $chr != "chrY" ]; then
			awk -v c="$chr" '$1==c' $range_out.tmp >> $range_out
			awk -v c="$chr" '$1==c' $in >> $var_out
		fi
	else
			awk -v c="$chr" '$1==c' $range_out.tmp >> $range_out
			awk -v c="$chr" '$1==c' $in >> $var_out
	fi
done < $work_dir/chrs_in_meta.txt
rm $range_out.tmp

