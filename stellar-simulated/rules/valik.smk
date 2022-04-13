bins = config["ibf_bins"]
segments = config["query_segments"]
w = config["window"]
k = config["kmer_length"]
size = config["ibf_size"]
overlap = config["pattern_overlap"]

import math
def get_error_count(wildcards):
        if (wildcards.er == "0"):
                e = 0
        e = int(math.ceil(float(wildcards.er) * min_len))
	print(e)
	return e

rule valik_split_ref:
        input:
                "ref_rep{rep}.fasta"
        output: 
                ref_meta = "valik/ref_rep{rep}.txt",
		seg_meta = "valik/ref_seg_rep{rep}.txt"
	benchmark:
		"benchmarks/valik_split_ref_rep{rep}.txt"
	shell:
		"valik split {input} --reference-output {output.ref_meta} --segment-output {output.seg_meta} --overlap {max_len} --bins {bins}"

rule valik_split_query:
	input:
		"query/with_insertions_rep{rep}_e{er}.fasta"
	output: 
		ref_meta = "valik/query_rep{rep}_e{er}.txt",
		seg_meta = "valik/query_seg_rep{rep}_e{er}.txt"
	benchmark:
		"benchmarks/valik_split_query_rep{rep}_er{er}.txt"
	shell:
		"valik split {input} --reference-output {output.ref_meta} --segment-output {output.seg_meta} --overlap {max_len} --bins {segments}"

rule create_query_segments:
	input:
		ref_meta = "valik/query_rep{rep}_e{er}.txt",
		seg_meta = "valik/query_seg_rep{rep}_e{er}.txt",
		query = "query/with_insertions_rep{rep}_e{er}.fasta"
	output: 
		"query/segments_rep{rep}_e{er}.fasta"
	benchmark:
		"benchmarks/create_segments_rep{rep}_er{er}.txt"
	shell:
		"../scripts/split_query.sh {input.seg_meta} {input.query} {output}"

rule valik_build:
	input:
		ref = "ref_rep{rep}.fasta",
		ref_meta = "valik/ref_rep{rep}.txt",
		seg_meta = "valik/ref_seg_rep{rep}.txt"
	output: 
		"valik/rep{rep}.index"
	benchmark:
		"benchmarks/valik_build_rep{rep}.txt"
	threads: 8
	shell:
		"valik build --from-segments {input.ref} --threads {threads} --window {w} --kmer {k} --output {output} --size {size} --seg-path {input.seg_meta} --ref-meta {input.ref_meta}"

rule valik_search:
	input:
		ibf = "valik/rep{rep}.index",
		query = "query/segments_rep{rep}_e{er}.fasta"
	output:
		"valik/search_rep{rep}_e{er}.out"
	threads: 8
	params:
		e = get_error_count
	benchmark:
		"benchmarks/valik_search_rep{rep}_er{er}.txt"
	shell:
		"valik search --index {input.ibf} --query {input.query} --error {params.e} --pattern {min_len} --overlap {overlap} --output {output} --p_max 1 --tau 1"
		
