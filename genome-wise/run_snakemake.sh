#!/bin/bash

snakemake --cores 32 --configfiles mouse_l50_config.yaml mouse_dream_config.yaml mouse_lastz_config.yaml mouse_blast_config.yaml last_config.yaml --snakefile Snakefile --config seg_count=480000 --keep-going

snakemake --cores 32 --configfiles human_l100_config.yaml human_dream_config.yaml human_lastz_config.yaml human_blast_config.yaml last_config.yaml --snakefile Snakefile_human --config seg_count=550000 -n
