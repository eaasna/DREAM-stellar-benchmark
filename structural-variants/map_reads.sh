#!/bin/bash

if [[ "$#" -ne 5 ]]; then
	echo "Usage: bash map_reads.sh <index> <reads> <mapped> <unmapped> <fasta>"
	exit
fi

index=$1
reads=$2
mapped=$3
unmapped=$4
fasta=$5

reads="$sample"
echo $sample
mapped="$sample_dir/pbmm2.bam"	

# alignments are discarded if they do not have at least 70% gap-compressed identity
# https://github.com/PacificBiosciences/pbmm2/blob/develop/README.md#how-do-you-define-gap-compressed-identity
unmapped="$sample_dir/unmapped.bam"	
fasta="$sample_dir/unmapped.fa"

echo "Align $reads"
pbmm2 align $index $reads $mapped --preset HIFI --unmapped

echo "Filter out unmapped"
samtools view --bam -f 4 $mapped > $unmapped
		
echo "Make fasta"
samtools view $unmapped | awk '{print ">"$1 "\t" $10 }' | sed 's/[ \t]\{1,\}/\n/' > $fasta

mapped_count=$(samtools view $mapped | wc -l | awk '{print $1}')
unmapped_count=$(samtools view $unmapped | wc -l | awk '{print $1}')
echo "$sample has $mapped_count mapped reads"
echo "$sample has $unmapped_count unmapped reads"

