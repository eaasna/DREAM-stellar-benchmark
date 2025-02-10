#!/bin/bash

set -e

cd /buffer/ag_abi/evelina/1000genomes/phase2/ftp.sra.ebi.ac.uk/vol1/run
truth="/buffer/ag_abi/evelina/1000genomes/phase2/freeze3.sv.alt.vcf"

for sample_id in "ERR386"; do
	#min_len=100
	#er=0.033
	min_len=50
	er=0.02
	sample_inv="$sample_id/potential_inversions_l${min_len}_e${er}.gff"
	cat $sample_id/*/potential_inversions_l${min_len}_e${er}/*.gff > $sample_inv

	awk '{print $1}' $sample_inv | sort | uniq > sample.chrs


	true_pos_count=0
	true_count=0
	all_local_count=0
	while read chr; do
		echo $chr
		grep -v '#' $truth | awk -v c=$chr '$1 == c {print $0}' | awk '{print $2 }' | rev | cut -c4- | rev > "sample.$chr.ground.truth"
		awk -v c=$chr '$1 == c {print $4}' $sample_inv | rev | cut -c4- | rev | grep -v -e '^$' > "sample.$chr.valik"

		(grep -f "sample.$chr.valik" "sample.$chr.ground.truth" > "sample.$chr.true" || \
			touch "sample.$chr.true")

		if [ -s sample.$chr.true ]; then
			echo $(cat sample.$chr.true)
			chr_true_pos_count=$(wc -l sample.$chr.true | awk '{print $1}')	
			true_pos_count=$((true_pos_count+chr_true_pos_count))
		fi
		chr_true_count=$(wc -l sample.$chr.ground.truth | awk '{print $1}')
		true_count=$((true_count+chr_true_count))
		
		chr_all_local_count=$(wc -l sample.$chr.valik | awk '{print $1}')
		all_local_count=$((all_local_count+chr_all_local_count))
	done < sample.chrs
	
	echo "true positive count $true_pos_count"
	echo "true count $true_count"
	echo "all local count $all_local_count"
done
