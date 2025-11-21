#!/bin/bash

set -ex

###################################### input parameters ###################################### 
ref="/srv/data/evelina/mouse/dna4.fasta"
query="/srv/data/evelina/fly/dna4.fasta"
ref_meta="/buffer/ag_abi/evelina/genome-wise/mouse/dream_agrippina/meta/b4096_fpr0.005_l50_e3_s11111010010100110111111.bin"

b=4096
max_er=0.06
p=50
fpr=0.005
numMatches=20000
sortThresh=20001
seg=480000
carts=1024
cap=1000
t=32

k=16
s="11111010010100110111111"


###################################### ref index ###################################### 
indexoutdir="/dev/shm/efficiency"
# build k-mer minimiser index
#dream-stellar build $ref --fast --verbose -n $b --error-rate $max_er --pattern $p \
#	--threads $t --output $indexoutdir/index.k$k.ibf --fpr $fpr --kmer $k &> $indexoutdir/index.k$k.build.err 
#rm $outdir/dna4.*.minimiser
#rm $outdir/dna4.*.header

# build gapped k-mer minimiser index
#dream-stellar build $ref --fast --verbose -n $b --error-rate $max_er --pattern $p \
#	--threads $t --output $indexoutdir/index.s$s.ibf --fpr $fpr \
#	--shape $s &> $indexoutdir/index.s$s.build.err
#rm $outdir/dna4.*.minimiser
#rm $outdir/dna4.*.header


###################################### search accuracy ###################################### 
function search_accuracy {
  local truth=$1
  local test=$2
  local out=$3

  min_overlap=$((p/2))
  ../scripts/search_accuracy.sh $truth $test $p $min_overlap $ref_meta $out
}

#echo "Testing bin cutoff values for adaptive seeding. Before this bin cutoff==1." >> "search_efficiency_0.04.log"
#echo "Testing bin cutoff values for adaptive seeding. Before this bin cutoff==1." >> "search_efficiency_0.06.log"
for bin_cutoff in 0.25 0.5; do
for er_count in 2 3; do
	er=$(bc <<< "scale=2;$er_count/$p")
	echo $er
	outdir="/buffer/ag_abi/evelina/efficiency_$er"
	log="search_efficiency_$er.log"
	acc_out="$outdir/valik.stellar.accuracy"
	truth="/buffer/ag_abi/evelina/genome-wise/mouse/stellar_agrippina/mouse_vs_fly_l50_e"$er_count"_rp1_rl1000.gff"
	
	mkdir -p $outdir

# distributed not prefiltered
search_out="$outdir/dist_stellar.gff"
#(/usr/bin/time -a -o $log -f "%e\t%M\t%x\tdist-no-prefilter\t%C" dream-stellar search --split-query --verbose \
#	--numMatches $numMatches --sortThresh $sortThresh --time --index $indexoutdir/index.k$k.ibf --query $query \
#	--error-rate $er --threads $t --output $search_out --stellar-only \
#	--bin-cutoff 1.0) &> $outdir/dist_stellar.search.err

# sequential k-mer filtered with thresh
if (( $(echo "$er_count == 1" |bc -l) )); then
   	thresh=13
elif (( $(echo "$er_count == 2" |bc -l) )); then
   	thresh=8
else
   	thresh=7
fi

search_out="$outdir/kmer_t1_thresh.gff"
(/usr/bin/time -a -o $log -f "%e\t%M\t%x\tseq-kmer-prefilter-same-thresh\t$bin_cutoff\t$er_count%C" \
	dream-stellar search --split-query \
	--cache-thresholds --seg-count $seg --cart-max-capacity $cap --max-queued-carts $carts \
	--numMatches $numMatches --sortThresh $sortThresh --time --index $indexoutdir/index.k$k.ibf \
	--query $query --error-rate $er --threads 1 --output $search_out --bin-cutoff $bin_cutoff \
	--threshold $thresh ) &> $outdir/kmer_t1_thresh.search.err

if [ -f $truth ];then
	search_accuracy $truth $search_out $acc_out
fi

# sequential k-mer filtered model thresh
search_out="$outdir/kmer_t1.gff"
(/usr/bin/time -a -o $log -f "%e\t%M\t%x\tseq-kmer-prefilter\t$bin_cutoff\t$er_count\t%C" \
	dream-stellar search --split-query \
	--cache-thresholds --seg-count $seg --cart-max-capacity $cap --max-queued-carts $carts \
	--numMatches $numMatches --sortThresh $sortThresh --time --index $indexoutdir/index.k$k.ibf \
	--query $query --error-rate $er --threads 1 --output $search_out --bin-cutoff $bin_cutoff) \
	&> $outdir/kmer_t1.search.err

if [ -f $truth ];then
	search_accuracy $truth $search_out $acc_out
fi

# sequential gapped k-mer filtered
search_out="$outdir/gapped_kmer_t1.gff"
(/usr/bin/time -a -o $log -f "%e\t%M\t%x\tseq-gapped-prefilter\t$bin_cutoff\t$er_count\t%C" \
	dream-stellar search --split-query \
	--cache-thresholds --seg-count $seg --cart-max-capacity $cap --max-queued-carts $carts \
	--numMatches $numMatches --sortThresh $sortThresh --time --index \
	$indexoutdir/index.s$s.ibf --query $query --error-rate $er --threads 1 \
	--output $search_out --bin-cutoff $bin_cutoff \
	--threshold $thresh) &> $outdir/gapped_kmer_t1.search.err

if [ -f $truth ];then
	search_accuracy $truth $search_out $acc_out
fi

# distributed k-mer filtered
search_out="$outdir/kmer.gff"
#(/usr/bin/time -a -o $log -f "%e\t%M\t%x\tdist-kmer-prefilter\t%C" dream-stellar search --split-query \
#	--cache-thresholds --seg-count $seg --cart-max-capacity $cap --max-queued-carts $carts \
#	--numMatches $numMatches --sortThresh $sortThresh --time --index $indexoutdir/index.k$k.ibf --query $query \
#	--error-rate $er --threads $t --output $search_out --bin-cutoff $bin_cutoff) &> $outdir/kmer.search.err

#if [ -f $truth ];then
#	search_accuracy $truth $search_out $acc_out
#fi

# distributed gapped k-mer filtered
search_out="$outdir/gapped_kmer.gff"
(/usr/bin/time -a -o $log -f "%e\t%M\t%x\tdist-gapped-prefilter\t$bin_cutoff\t$er_count\t%C" dream-stellar search --split-query \
	--cache-thresholds --seg-count $seg --cart-max-capacity $cap --max-queued-carts $carts \
	--numMatches $numMatches --sortThresh $sortThresh --time --index \
	$indexoutdir/index.s$s.ibf --query $query --error-rate $er --threads $t \
	--output $outdir/gapped_kmer.gff --bin-cutoff $bin_cutoff) &> $outdir/gapped_kmer.search.err

if [ -f $truth ];then
	search_accuracy $truth $search_out $acc_out
fi

# not distributed not prefiltered
search_out="$outdir/stellar.gff"
#(/usr/bin/time -a -o $log -f "%e\t%M\t%x\tno-dist-no-prefilter\t%C" stellar -a dna --numMatches $numMatches \
#	--sortThresh $sortThresh $ref $query -e $er -l $p -o $search_out) &> outdir/stellar.search.err

done
done
