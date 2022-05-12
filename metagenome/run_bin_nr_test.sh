#!/usr/bin/env bash

size=${1}
er=0.05

# for bins in 8 64 1024 8192 16384
for bins in 1024
do
snakemake --cores 1 --snakefile Snakefile_simulate --configfile $size/config.yaml --config error_rate=$er ibf_bins=$bins --
( /usr/bin/time -a -o $size/dream.time -f "%e\t%M\t%x\t%C" snakemake --cores 16 --snakefile Snakefile_dream --configfile $size/config.yaml --config error_rate=$er ibf_bins=$bins -- ) 2> $size/dream.err
( /usr/bin/time -a -o $size/stellar.time -f "%e\t%M\t%x\t%C" snakemake --cores 16 --snakefile Snakefile_stellar --configfile $size/config.yaml --config error_rate=$er ibf_bins=$bins -- ) 2> $size/stellar.err
rm -r /dev/shm/$bins/queries
done

# snakemake --cores 1 --snakefile Snakefile_evaluate --configfile $size/config.yaml --config error_rate=$er ibf_bins=$bins --
