#!/usr/bin/env bash
set -x

# Split a single reference sequence
snakemake --use-conda --cores 8 --configfile 100kb/config.yaml --snakefile Snakefile_split
snakemake --use-conda --cores 8 --configfile 100kb/config.yaml --snakefile Snakefile_split

