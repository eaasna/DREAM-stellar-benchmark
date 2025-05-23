#!/usr/bin/env bash

# (w, k)-minimisers
snakemake --cores 16 --configfile size_1_haplotype/config.yaml --forceall
snakemake --cores 16 --configfile size_8_haplotypes/config.yaml --forceall
# snakemake --cores 16 --configfile overlap/config.yaml

# (k, k)-minimisers
snakemake --cores 16 --configfile size_1_haplotype_kmers/config.yaml --forceall
snakemake --cores 16 --configfile size_8_haplotypes_kmers/config.yaml --forceall
# snakemake --cores 16 --configfile overlap_kmers/config.yaml
