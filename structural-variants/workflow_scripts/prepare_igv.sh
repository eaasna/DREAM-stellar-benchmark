#!/bin/bash

set -e

if [[ "$#" -ne 6 ]]; then
	echo "Usage: bash prepare_igv.sh <read_ranges> <sample> <min len> <er> <chr> <read id>"
	exit 1
fi

all_read_ranges=$1
sample=$2
min_len=$3
er=$4
chr=$5
read_id=$6
inv="${chr}_${read_id}.gff"

work_dir="$(dirname $all_read_ranges)"
cd $work_dir

in_dir="$sample/potential_inversions_l${min_len}_e${er}"
out_dir="$sample/try_igv_l${min_len}_e${er}"
mkdir -p $out_dir

plus_read_range="$out_dir/${chr}_${read_id}_plus_read_range.gff"
plus_var="$out_dir/${chr}_${read_id}_plus_var.gff"
if [ -f $plus_read_range ]; then
	rm $plus_read_range
fi

minus_read_range="$out_dir/${chr}_${read_id}_minus_read_range.gff"
minus_var="$out_dir/${chr}_${read_id}_minus_var.gff"
if [ -f $minus_read_range ]; then
	rm $minus_read_range
fi

# get chromosome matches and filter out non unique query database pairs
awk -v c="$chr" '$1==c'  $in_dir/$inv | awk '$7=="+"' | tac | awk -F';' '{print $0 "\t" $2}' | awk '!seen[$4 FS $5 FS $10]++' | tac | cut -f-9 > $plus_var
awk -v c="$chr" '$1==c'  $in_dir/$inv | awk '$7=="-"' | tac | awk -F';' '{print $0 "\t" $2}' | awk '!seen[$4 FS $5 FS $10]++' | tac | cut -f-9 > $minus_var

qname=$(head -n 1 $minus_var | awk '{print $9}' | awk -F';' '{print $1}')

if [ ! -s $all_read_ranges ]; then
	echo "Can't find read length from $all_read_ranges"
	exit 1
fi

match=$(grep $qname $all_read_ranges | head -n 1)
qlen=$(echo $match | awk '{print $9}' | awk -F';' '{print $6}' | sed 's/qlen=//g' | awk '{print $1}' )

#echo $match
#echo $qlen

while read match; do
	qstart=$(echo $match | awk '{print $9}' | awk -F';' '{print $2}' | sed 's/seq2Range=//g' | awk -F',' '{print $1}')
	qend=$(echo $match | awk '{print $9}' | awk -F';' '{print $2}' | sed 's/seq2Range=//g' | awk -F',' '{print $2}')
	qoffset=$(bc <<< $qlen-$qend)

	# this correction is only necessary because something goes wrong with the read range conversion in the previous ste
	echo $match | awk -v qs="$qstart" -v qo="$qoffset" -v ql="$qlen" '{print $1 "\t" $2 "\t" $3 "\t" $4-qs "\t" $5+qo "\t" $6 "\t" $7 "\t" $8 "\t" $9 ";qlen=" ql}'	>> $plus_read_range
done < $plus_var 

plus_supported_by_multiple_alignments=$(awk '{print $4}' $plus_read_range | rev | cut -c3- | rev | sort | uniq -c | awk '$1>1' | wc -l)

if [ $plus_supported_by_multiple_alignments -ge 2 ]; then
	echo "${chr} ${read_id} plus"
fi


while read match; do
	qstart=$(echo $match | awk '{print $9}' | awk -F';' '{print $2}' | sed 's/seq2Range=//g' | awk -F',' '{print $1}')
	qend=$(echo $match | awk '{print $9}' | awk -F';' '{print $2}' | sed 's/seq2Range=//g' | awk -F',' '{print $2}')
	qoffset=$(bc <<< $qlen-$qend)
	# this correction is only necessary because something goes wrong with the read range conversion in the previous ste
	echo $match | awk -v qs="$qstart" -v qo="$qoffset" -v ql="$qlen" '{print $1 "\t" $2 "\t" $3 "\t" $4-qs "\t" $5+qo "\t" $6 "\t" $7 "\t" $8 "\t" $9 ";qlen=" ql}'	>> $minus_read_range
done < $minus_var 

minus_supported_by_multiple_alignments=$(awk '{print $4}' $minus_read_range | rev | cut -c3- | rev | sort | uniq -c | awk '$1>1' | wc -l)

if [ $minus_supported_by_multiple_alignments -ge 2 ]; then
	echo "${chr} ${read_id} minus"
fi


if [ $plus_supported_by_multiple_alignments -le 1 ] && [ $minus_supported_by_multiple_alignments -le 1 ]; then
	rm $plus_var
	rm $plus_read_range
	rm $minus_var
	rm $minus_read_range
fi

