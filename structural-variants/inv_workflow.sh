#!/bin/bash

set -e

if [[ "$#" -ne 4 ]]; then
	echo "Usage: bash inv_workflow.sh <alignments path> <sample ID> <min_len> <er>"
	exit 1
fi

alignments=$1
sample=$2
min_len=$3
er=$4
read_ranges="$(dirname $alignments)/${sample}_l${min_len}_e${er}_read_range.fp.gff"

./workflow_scripts/find_inversions.sh $alignments $sample $min_len $er

work_dir=$(dirname $alignments)
file_ids=$(ls -lrth $work_dir/$sample/potential_inversions_l${min_len}_e$er | awk '{print $9}' | grep -v chrY)

for f in $file_ids;do
	chr=$(echo $f | awk -F'_' '{print $1}')
	read_id=$(echo $f | awk -F'_' '{print $2}' | sed 's/.gff//g')
	./workflow_scripts/prepare_igv.sh $read_ranges $sample $min_len $er $chr $read_id 	
	echo -e "$chr\t$read_id"
done
