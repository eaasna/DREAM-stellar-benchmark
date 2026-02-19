#!/bin/bash

set -ex

#dream_stellar="/group/ag_abi/evelina/valik/build_io/bin/dream-stellar"
#prefix="io_on_demand"
dream_stellar="/group/ag_abi/evelina/valik/build/bin/dream-stellar"
prefix="read_all"

###################################### make ref index ###################################### 

function make_index {
    ref=$1
    index=$2
    mkdir -p $indexoutdir
    # build k-mer minimiser index
    #$dream_stellar build $ref --fast --verbose -n $b --error-rate $max_er --pattern $p \
    #	--threads $t --output $indexoutdir/index.k$k.ibf --fpr $fpr --kmer $k &> $indexoutdir/index.k$k.build.err 

    # build gapped k-mer minimiser index
    #$dream_stellar build $ref --fast --verbose -n $b --error-rate $max_er --pattern $p --shape $s \
    #	--threads $t --output $indexoutdir/index.s$s.ibf --fpr $fpr &> $indexoutdir/index.s$s.build.err

    # build default gapped k-mer minimiser index
    $dream_stellar build $ref --fast --verbose -n $b --error-rate $max_er --pattern $p \
   	--threads $t --output $index --fpr $fpr &> $indexoutdir/index.build.err
    
    rm $indexoutdir/rep*.minimiser
    rm $indexoutdir/rep*.header
}

###################################### find search accuracy ###################################### 
function search_accuracy {
  local truth=$1
  local test=$2
  local out=$3
  local stype=$4

  match_count=`wc -l $test | awk '{print $1}'`
  echo -e "$test\t$match_count\t" >> $out

  min_overlap=$((p/2))
  local tmp_out="$outdir/tmp.log"
  ../scripts/search_accuracy.sh $truth $test $p $min_overlap $ref_meta $tmp_out
  
  truncate -s -1 $out
  tail -n 1 $tmp_out >> $out
  rm $tmp_out

  truncate -s -1 $out
  echo -e "\t$bin_cutoff\t$er_count\t$stype\t$truth" >> $out
}

###################################### input data #####################################

ref_size="100Mb"
data_dir="/srv/data/evelina/markov/$ref_size"

indexoutdir="/dev/shm/markov/$ref_size"
run_build=1

###################################### input parameters #####################################

p=50
max_er=0.1
er_count=5
er=$(bc <<< "scale=2;$er_count/$p")
ERROR_RATE="$er"
fpr=0.005
numMatches=3000000
sortThresh=3000001

bin_cutoff=$1
t=4
reps=5

# defaults
b=1024
seg=3500
carts=1000
cap=1000

# only for manual k-mer size
k=16
s="11111010010100110111111"

for rep in $(seq 1 $reps); do

runid="rep${rep}_e0${er}"
data_out_dir="/buffer/ag_abi/evelina/markov/$ref_size/"
outdir="$data_out_dir/$prefix/efficiency_${runid}"
log="search_efficiency_${runid}.log"
acc_out="$outdir/valik.stellar.accuracy"
truth="$data_out_dir/dist_stellar/${runid}.gff"

query="$data_dir/small_rep${rep}.fasta"
ref="$data_dir/ref/${runid}.fasta"
index="$indexoutdir/${runid}.index"
ref_meta="$indexoutdir/${runid}.bin"

if [ $run_build -eq 1 ]; then
	make_index $ref $index
fi
mkdir -p $outdir

# distributed not prefiltered
if [ ! -f $truth ]; then
(/usr/bin/time -a -o $log -f "%e\t%M\t%x\tdist-no-prefilter\t%C" $dream_stellar search --split-query --verbose \
	--numMatches $numMatches --sortThresh $sortThresh --time --index $index --query $query \
	--error-rate $er --threads $t --output $truth --stellar-only \
	--bin-cutoff 1.0) &> $outdir/dist_stellar.search.err
fi

for seg in 10 20 50 250 500 1000 2000 4000 8000; do
for cap in 1000; do
for carts in 1000; do

search_out="$outdir/kmer_t1_thresh.gff"
search_type="seq-kmer-prefilter-same-thresh"
#(/usr/bin/time -a -o $log -f "%e\t%M\t%x\t$search_type\t$bin_cutoff\t$er_count%C" \
#	$dream_stellar search --split-query \
#	--cache-thresholds --seg-count $seg --cart-max-capacity $cap --max-queued-carts $carts \
#	--numMatches $numMatches --sortThresh $sortThresh --time --index $index_kmer \
#	--query $query --error-rate $er --threads 1 --output $search_out --bin-cutoff $bin_cutoff \
#	--threshold $thresh ) &> $outdir/kmer_t1_thresh.search.err

#if [ -f $truth ];then
#	search_accuracy $truth $search_out $acc_out $search_type
#fi

# sequential k-mer filtered model thresh
search_out="$outdir/kmer_t1.gff"
search_type="seq-kmer-prefilter"
#(/usr/bin/time -a -o $log -f "%e\t%M\t%x\t$search_type\t$bin_cutoff\t$er_count\t%C" \
#	$dream_stellar search --split-query \
#	--cache-thresholds --seg-count $seg --cart-max-capacity $cap --max-queued-carts $carts \
#	--numMatches $numMatches --sortThresh $sortThresh --time --index $index_kmer \
#	--query $query --error-rate $er --threads 1 --output $search_out --bin-cutoff $bin_cutoff) \
#	&> $outdir/kmer_t1.search.err

#if [ -f $truth ];then
#	search_accuracy $truth $search_out $acc_out $search_type
#fi

# sequential gapped k-mer filtered
#search_out="$outdir/gapped_kmer_t1.gff"
#search_type="seq-gapped-prefilter"
#(/usr/bin/time -a -o $log -f "%e\t%M\t%x\t$search_type\t$bin_cutoff\t$er_count\t%C" \
#	$dream_stellar search --split-query \
#	--cache-thresholds --seg-count $seg --cart-max-capacity $cap --max-queued-carts $carts \
#	--numMatches $numMatches --sortThresh $sortThresh --time --index \
#	$index --query $query --error-rate $er --threads 1 \
#	--output $search_out --bin-cutoff $bin_cutoff) &> $outdir/gapped_kmer_t1.search.err

#if [ -f $truth ];then
#	search_accuracy $truth $search_out $acc_out $search_type
#fi

# distributed k-mer filtered
search_out="$outdir/kmer.gff"
search_type="dist-kmer-prefilter"
#(/usr/bin/time -a -o $log -f "%e\t%M\t%x\t$search_type\t%C" $dream_stellar search --split-query \
#	--cache-thresholds --seg-count $seg --cart-max-capacity $cap --max-queued-carts $carts \
#	--numMatches $numMatches --sortThresh $sortThresh --time --index $index_kmer --query $query \
#	--error-rate $er --threads $t --output $search_out --bin-cutoff $bin_cutoff) &> $outdir/kmer.search.err

#if [ -f $truth ];then
#	search_accuracy $truth $search_out $acc_out $search_type
#fi

# distributed gapped k-mer filtered
search_out="$outdir/gapped_kmer.gff"
search_type="dist-gapped-prefilter"
#(valgrind --tool=massif --log-file="${search_type}.massif.log" \
(/usr/bin/time -a -o $log -f "%e\t%M\t%x\t$search_type\t$bin_cutoff\t$er_count\t%C" \
	$dream_stellar search --split-query \
	--cache-thresholds --seg-count $seg --cart-max-capacity $cap --max-queued-carts $carts \
	--numMatches $numMatches --sortThresh $sortThresh --time --index \
	$index --query $query --error-rate $er --threads $t --verbose \
	--output $outdir/gapped_kmer.gff --bin-cutoff $bin_cutoff) 
	#&> $outdir/gapped_kmer.search.err
	matches=`wc -l $outdir/gapped_kmer.gff | awk '{print $1}'`
	truncate -s -1 $log
	echo -e "$matches" >> $log

if [ -f $truth ];then
	search_accuracy $truth $search_out $acc_out $search_type
fi

# sequential k-mer filtered with thresh
#if (( $(echo "$er_count == 1" |bc -l) )); then
 #  	thresh=13
#elif (( $(echo "$er_count == 2" |bc -l) )); then
 #  	thresh=8
#else
 #  	thresh=7
#fi
# distributed gapped k-mer filtered with thresh
search_out="$outdir/gapped_kmer_thresh.gff"
search_type="dist-gapped-prefilter-thresh"
#(/usr/bin/time -a -o $log -f "%e\t%M\t%x\t$search_type\t$bin_cutoff\t$er_count\t%C" \
#	$dream_stellar search --split-query \
#	--cache-thresholds --seg-count $seg --cart-max-capacity $cap --max-queued-carts $carts \
#	--numMatches $numMatches --sortThresh $sortThresh --time --index \
#	$index --query $query --error-rate $er --threads $t \
#	--output $outdir/gapped_kmer_thresh.gff --bin-cutoff $bin_cutoff \
#	--threshold $thresh ) &> $outdir/gapped_kmer_thresh.search.err

#if [ -f $truth ];then
#	search_accuracy $truth $search_out $acc_out $search_type
#fi

# not distributed not prefiltered
search_out="$outdir/stellar.gff"
search_type="no-dist-no-prefilter"
#(/usr/bin/time -a -o $log -f "%e\t%M\t%x\t$search_type\t%C" stellar -a dna --numMatches $numMatches \
#	--sortThresh $sortThresh $ref $query -e $er -l $p -o $search_out) &> outdir/stellar.search.err

done
done
done
done
