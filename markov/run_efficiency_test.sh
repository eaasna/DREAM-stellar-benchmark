#!/bin/bash

set -ex

execs=(markov_genome generate_local_matches)
for exec in "${execs[@]}"; do
    if ! which ${exec} &>/dev/null; then
        echo "${exec} is not available"
        echo ""
        echo "make sure \"${execs[@]}\" are reachable via the \${PATH} variable"
        echo ""

        # trying to do some guessing here:
        paths+=(/group/ag_abi/evelina/DREAM-stellar-benchmark/lib/raptor_data_simulation/build/bin)
        paths+=(./group/ag_abi/evelina/DREAM-stellar-benchmark/lib/raptor_data_simulation/build/src/mason2/src/mason2-build/bin)
	paths+=(/group/ag_abi/evelina/markov_genome/target/release)
        p=""
        for pp in ${paths[@]}; do
            p=${p}$(realpath -m $pp):
        done
        echo "you could try "
        echo "export PATH=${p}\${PATH}"

        exit 127
    fi
done

#dream_stellar="/group/ag_abi/evelina/valik/build_io/bin/dream-stellar"
#prefix="io_on_demand"
dream_stellar="/group/ag_abi/evelina/valik/debug/bin/dream-stellar"
prefix="read_all_massif"

###################################### data simulation #####################################

REF_IN="/srv/data/evelina/mouse/dna4.fasta"
ref_size="10Mb"

REF_OUT="/srv/data/evelina/markov/$ref_size/large_rep0.fasta"
REF_LENGTH=10485760
REF_SEED=15

QUERY_OUT="/srv/data/evelina/markov/$ref_size/small_rep0.fasta"
QUERY_LENGTH=104858
QUERY_SEED=9010
ORDER=3

REP=0
data_dir="/srv/data/evelina/markov/$ref_size"
DIR=$data_dir
MIN_LEN=50
MAX_LEN=200

MATCH_COUNT=10485
ERROR_RATE="0.06"

run_simulation=1
run_build=1


if [ $run_simulation -eq 1 ]; then
	echo "Simulating reference of length $REF_LENGTH with seed $REF_SEED"
	len=$(( $REF_LENGTH / 10 ))
	markov_genome simulate --seed $REF_SEED --order $ORDER --input $REF_IN --lens $len --lens $len --lens $len --lens $len --lens $len --lens $len --lens $len --lens $len --lens $len --lens $len --output $REF_OUT

	len=$(( $QUERY_LENGTH / 10 ))
	echo "Simulating query of length $QUERY_LENGTH with seed $QUERY_SEED"
	markov_genome simulate --seed $QUERY_SEED --order $ORDER --input $REF_IN --lens $len --lens $len --lens $len --lens $len --lens $len --lens $len --lens $len --lens $len --lens $len --lens $len --output $QUERY_OUT

	echo "Sampling $MATCH_COUNT local matches between $MIN_LEN and $MAX_LEN bp with an error rate of $ERROR_RATE"

	mkdir -p local_matches
	mkdir -p ref
	generate_local_matches \
		--matches-out $DIR/local_matches/rep${REP}_e${ERROR_RATE}.fasta \
		--genome-out $DIR/ref/rep${REP}_e${ERROR_RATE}.fasta \
		--max-error-rate $ERROR_RATE \
		--num-matches $MATCH_COUNT \
		--min-match-length $MIN_LEN \
		--max-match-length $MAX_LEN \
		--ref-len $QUERY_LENGTH \
		--verbose-ids \
		--normal \
		--query $DIR/large_rep${REP}.fasta \
		$DIR/small_rep${REP}.fasta 1> $DIR/match_positions.txt
		#2> /dev/null


	truth_file="${DIR}/ground_truth/rep${REP}_e${ERROR_RATE}.tsv"
	grep ">" $DIR/local_matches/rep${REP}_e${ERROR_RATE}.fasta | cut -c 2- | awk -F, '{ print $1 " " $2 }' | sed 's/start_position=//g' | sed 's/length=//g' | awk '{print $2 "\t" $2+$3 }' > $truth_file
	sort -g -k2 $truth_file -o $truth_file
fi


###################################### input parameters #####################################
rep=0
max_er=0.1

query="$data_dir/small_rep${rep}.fasta"
ref_meta="$data_dir/rep${rep}_e${er}.bin"

b=1024
p=50
fpr=0.005
numMatches=3000000
sortThresh=3000001
#seg=3495
seg=349
carts=1024
cap=500

k=16
s="11111010010100110111111"

###################################### ref index ###################################### 
indexoutdir="/dev/shm/markov/$ref_size/"


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

###################################### search accuracy ###################################### 
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

bin_cutoff=0.5
er_count=3
for t in 1; do
for cap in 1000; do
for carts in 1024; do
	er=$(bc <<< "scale=2;$er_count/$p")
	echo $er
	outdir="/buffer/ag_abi/evelina/markov/$ref_size/$prefix/efficiency_0$er"
	log="search_efficiency_0$er.log"
	acc_out="$outdir/valik.stellar.accuracy"
	truth="work/$ref_size/dist_stellar/rep${rep}_${er}.gff"
	
	ref="$data_dir/ref/rep${rep}_e0${er}.fasta"
	index="$indexoutdir/rep${rep}_e0${er}.index"
	if [ $run_build -eq 1 ]; then
		make_index $ref $index
	fi

	mkdir -p $outdir

# distributed not prefiltered
search_out="$outdir/dist_stellar.gff"
#(/usr/bin/time -a -o $log -f "%e\t%M\t%x\tdist-no-prefilter\t%C" $dream_stellar search --split-query --verbose \
#	--numMatches $numMatches --sortThresh $sortThresh --time --index $index --query $query \
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
#(/usr/bin/time -a -o $log -f "%e\t%M\t%x\t$search_type\t$bin_cutoff\t$er_count\t%C" \
(valgrind --tool=massif --log-file="${search_type}.massif.log" \
	$dream_stellar search --split-query \
	--cache-thresholds --seg-count $seg --cart-max-capacity $cap --max-queued-carts $carts \
	--numMatches $numMatches --sortThresh $sortThresh --time --index \
	$index --query $query --error-rate $er --threads $t \
	--output $outdir/gapped_kmer.gff --bin-cutoff $bin_cutoff) 
	#&> $outdir/gapped_kmer.search.err
	matches=`wc -l $outdir/gapped_kmer.gff | awk '{print $1}'`
	truncate -s -1 $log
	echo -e "$matches" >> $log

if [ -f $truth ];then
	search_accuracy $truth $search_out $acc_out $search_type
fi

# distributed gapped k-mer filtered with thresh
search_out="$outdir/gapped_kmer_thresh.gff"
search_type="dist-gapped-prefilter-thresh"
#(/usr/bin/time -a -o $log -f "%e\t%M\t%x\t$search_type\t$bin_cutoff\t$er_count\t%C" \
#	$dream_stellar search --split-query \
#	--cache-thresholds --seg-count $seg --cart-max-capacity $cap --max-queued-carts $carts \
#	--numMatches $numMatches --sortThresh $sortThresh --time --index \
#	$index --query $query --error-rate $er --threads $t \
#	--output $outdir/gapped_kmer_thresh.gff --bin-cutoff $bin_cutoff \
#	--threshold 2 ) &> $outdir/gapped_kmer_thresh.search.err

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
