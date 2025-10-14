#!/bin/bash

set -ex

# mouse
for seg_count in 15000 30000 60000 120000 240000 480000; do
	snakemake --cores 32 --configfiles mouse_l50_seg_len_config.yaml mouse_dream_config.yaml mouse_lastz_config.yaml last_config.yaml mouse_blast_config.yaml --config seg_count=$seg_count --snakefile Snakefile_wo_eval
	rm mouse/dream/b4096_fpr0.005_l50_cmin0_cmax50_e*_s11111010010100110111111_ent1.0_cap*_carts*_t32.gff
done

seg_count=60000
snakemake --cores 32 --configfiles mouse_l50_seg_len_config.yaml mouse_dream_bins_config.yaml mouse_lastz_config.yaml last_config.yaml mouse_blast_config.yaml --config seg_count=$seg_count --snakefile Snakefile_wo_eval

# human
#for seg_count in 1250000 1500000; do
#	snakemake --cores 32 --configfiles human_l100_config.yaml human_dream_config.yaml human_lastz_config.yaml last_config.yaml human_blast_config.yaml --config seg_count=$seg_count --snakefile Snakefile_wo_eval
#	rm human/dream_gapped/b4096_fpr0.005_l100_cmin0_cmax50_e5_s11111010010100110111111_ent1.0_cap1000_carts1024.gff
#done
