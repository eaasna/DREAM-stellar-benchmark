# Local alignment
[DREAM-Stellar](https://github.com/eaasna/DREAM-Stellar) is a fast and accurate tool for finding local alignments between sets of DNA sequences. The valid set of local alignments is defined by a minimum length and a maximum number of errors. 

## Reproducing Stellar results
The DREAM-Stellar alignment algorithm is an offshoot of the Stellar aligner:
- Kehr, B., Weese, D. & Reinert, K. STELLAR: fast and exact local alignments. BMC Bioinformatics 12 (Suppl 9), S15 (2011). https://doi.org/10.1186/1471-2105-12-S9-S15

The [reproduce-stellar](reproduce-stellar/) benchmark uses simulated sequences where the truth set of alignments is known to assess the runtime and accuracy of DREAM-Stellar compared to the exact Stellar aligner.

## Genome-wise comparison
Both the reference and query sets of sequences are split into shorter segments to apply a distribution strategy on the linear genomes. The [genome-wise](genome-wise/) comparison benchmark contains examples of using DREAM-Stellar on real reference genomes.

## Download and installation

Clone testing repository:
```
git clone --recurse-submodules git@github.com:eaasna/DREAM-stellar-benchmark.git
```
Build data simulation library:
```
cd DREAM-stellar-benchmark/lib/raptor_data_simulation
mkdir build && cd build
cmake ../
make
```
You might need to copy the `mason_genome` binary into the `raptor_data_simulation/build/bin` directory. 
```
cd ../
cp build/src/mason2/src/mason2-build/bin/mason_genome build/bin/mason_genome
```

Build DREAM-Stellar and add the valik binaries to $PATH:
https://github.com/eaasna/valik

Other requirements:
* Biopython https://biopython.org/wiki/Packages
