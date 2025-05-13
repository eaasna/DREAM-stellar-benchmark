#!/bin/bash

set -ex 

stellar="l50_e2"
min_len=50
min_percid=96

function count_last_matches() {
	m=$1
	fn_gff="$data_dir/$stellar/mouse_vs_fly_w1_k1_m$m.fn.gff"
	all_matches="$data_dir/mouse_vs_fly_w1_k1_m$m.bed"
	out_dir="m${m}_last_vs_stellar_$stellar"
	mkdir -p $out_dir

	awk '{print $1 "\t" $9}' $fn_gff  | awk -F';' '{print $1}' | sort | uniq -c | awk '{print $1 "\t" $2 "\t" $3}' > $out_dir/fn_count_table.tsv

	grep -v "#" $all_matches | awk -v l="$min_len" -v p="$min_percid" '($9 - $8) < l && $4 < p { print $1 "\t" $7}' | sort | uniq -c | awk '{print $1 "\t" $2 "\t" $3}' > $out_dir/fp_count_table.tsv
}


function count_lastz_matches {
	s=$1
	fn_gff="$data_dir/$stellar/mouse_vs_fly_s111101001100101011111_gapped_transition_$s.fn.gff"
	all_matches="$data_dir/mouse_vs_fly_s111101001100101011111_gapped_transition_$s.bed"
	out_dir="s${s}_lastz_vs_stellar_$stellar"
	mkdir -p $out_dir

	awk '{print $1 "\t" $9}' $fn_gff  | awk -F';' '{print $1}' | sort | uniq -c | awk '{print $1 "\t" $2 "\t" $3}' > $out_dir/fn_count_table.tsv

	grep -v "#" $all_matches | awk -v l="$min_len" -v p="$min_percid" ' ($3 - $2) < l && $4 < p { print $1 "\t" $7}' | sort | uniq -c | awk '{print $1 "\t" $2 "\t" $3}' > $out_dir/fp_count_table.tsv
}

function count_blast_matches() {
	e=$1
	k=$2
	fn_gff="$data_dir/$stellar/mouse_vs_fly_e${e}_k$k.fn.gff"
	all_matches="$data_dir/mouse_vs_fly_e${e}_k$k.bed"
	out_dir="e${e}_k${k}_blast_vs_stellar_$stellar"
	mkdir -p $out_dir

	awk '{print $1 "\t" $9}' $fn_gff  | awk -F';' '{print $1}' | sort | uniq -c | awk '{print $1 "\t" $2 "\t" $3}' > $out_dir/fn_count_table.tsv

	awk -v l="$min_len" '{ if (($5=="plus" && $3-$2 < l) || ($5=="minus" && $2-$3 < l)) print $0}' $all_matches | awk -v p="$min_percid" '{if ($4 < p) print $1 "\t" $7}' | sort | uniq -c | awk '{print $1 "\t" $2 "\t" $3}' > $out_dir/fp_count_table.tsv
}

data_dir="/group/ag_abi/evelina/DREAM-stellar-benchmark/genome-wise/mouse/last_agrippina"
count_last_matches 100
count_last_matches 10

data_dir="/group/ag_abi/evelina/DREAM-stellar-benchmark/genome-wise/mouse/lastz_agrippina"
count_lastz_matches 3
count_lastz_matches 30

data_dir="/group/ag_abi/evelina/DREAM-stellar-benchmark/genome-wise/mouse/blast_agrippina"
count_blast_matches 10 28
count_blast_matches 10 24

#count_blast_matches "1e-5" 28
#count_blast_matches "1e-5" 24
