rule ref_to_dna4:
	input:
		"/buffer/ag_abi/evelina/fly/dmel-all-chromosome-r6.59.fasta"
	output:
		"/buffer/ag_abi/evelina/fly/dna4.fa"
		#"/buffer/ag_abi/evelina/dna4.fa"
	shell:      
		"st_dna5todna4 {input} > {output}"

rule query_to_dna4:
	input:
		#"/buffer/ag_abi/evelina/mouse/GCF_000001635.27_GRCm39_genomic.fna"
		"/buffer/ag_abi/evelina/mouse/chr1.fa"
	output:
		"/buffer/ag_abi/evelina/mouse/dna4.fa"
	shell:      
		"st_dna5todna4 {input} > {output}"

