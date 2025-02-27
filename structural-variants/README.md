1. bash get_variants.sh 

Download the structural variant truth set and convert it to a bed format.

2. bash sv_workflow.sh

Map all reads and find local alignments for reads that did not map. 

From the list of local alignments ./workflow_scripts/convert_valik_gff.sh creates two output files.
- var files with the original local alignments
- read ranges where the complete read is anchored to the reference based on the local alignments

For variants and read ranges ./workflow_scripts/evaluate_accuracy.sh finds the overlap with known structural variants.
TODO: something went wrong when converting ranges back to variants.

3. bash inv_workflow.sh 

Analyse the false positive variants to try to detect inversions that were not found in the truth set. 

Find reads that have local alignments on both strands of the reference ./workflow_scripts/find_inversions.sh 
Further narrow down the set of inversions by requiring multiple local alignments to anchor the read ./workflow_scripts/prepare_igv.sh

