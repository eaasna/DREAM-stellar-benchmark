f = open("valik.time", "a")
f.write("#### PARAMS ####\n")
for par in config:
	f.write(par + '\t' + str(config[par]) + '\n')
f.write("#### LOG ####\n")
f.write("Time\tMemory\tExitcode\tCommand\tThreads\n")
f.close()


rule valik_split_ref:
	input:
		"ref.fasta"
	output: 
		ref_meta = "split/ref.txt",
		seg_meta = "split/seg.txt"
	shell:
		"""
		( /usr/bin/time -a -o valik.time -f "%e\t%M\t%x\tvalik-split\t{threads}" valik split {input} --ref-meta {output.ref_meta} --seg-meta {output.seg_meta} --overlap {max_len} --bins {bins})
		"""

rule valik_split_query:
	input:
		query = "queries/e{er}.fastq",
	output: 
		ref_meta = "split/ref.txt",
		seg_meta = "split/seg.txt"
	shell:
		"""
		( /usr/bin/time -a -o valik.time -f "%e\t%M\t%x\tvalik-split\t{threads}" valik split {input} --ref-meta {output.ref_meta} --seg-meta {output.seg_meta} --overlap {max_len} --bins {bins})
		"""

rule valik_build:
	input:
		fasta = "ref.fasta",
		ref_meta = "split/ref.txt",
		seg_meta = "split/seg.txt"
	output: 
		ibf = temp("/dev/shm/valik.index")
	threads: 8
	shell:
		"""
		( /usr/bin/time -a -o valik.time -f "%e\t%M\t%x\tvalik-build\t{threads}" valik build {input.fasta} --seg-meta {input.seg_meta} --ref-meta {input.ref_meta} --from-segments --window {w} --kmer {k} --output {output.ibf} --size {size} --threads {threads})
		"""

rule valik_distributed_search:
	input:
		ibf = "/dev/shm/valik.index",
		query = "queries/e{er}.fastq",
		ref_meta = "split/ref.txt",
		seg_meta = "split/seg.txt"
	output:
		read_bins = "search/distributed_e{er}.gff"
	threads: search_threads
	params:
		e = get_search_error_count
	shell:
		"""
		( /usr/bin/time -a -o valik.time -f "%e\t%M\t%x\tvalik-distributed-search\t{threads}" valik search --time --cart_max_capacity {cart_capacity} --max_queued_carts {queued_carts} --index {input.ibf} --ref-meta {input.ref_meta} --seg-meta {input.seg_meta} --query {input.query} --error {params.e} --pattern {pattern} --overlap {overlap} --threads {threads} --output {output.read_bins})
		"""
		
rule valik_distributed_consolidate:
	input:
		alignment = "search/distributed_e{er}.gff",
		ref_meta = "split/ref.txt",
		seg_meta = "split/seg.txt"
	output:
		"search/consolidated_distributed_e{er}.gff"
	threads: 1
	params:
		e = get_search_error_count
	shell:
		"""
		( /usr/bin/time -a -o valik.time -f "%e\t%M\t%x\tvalik-distributed-consolidate\t{threads}" valik consolidate --input {input.alignment} --ref-meta {input.ref_meta} --output {output})
		"""
rule valik_local_search:
	input:
		dist_mutex = "search/consolidated_distributed_e{er}.gff",
		ibf = "/dev/shm/valik.index",
		query = "queries/e{er}.fastq",
		ref_meta = "split/ref.txt",
		seg_meta = "split/seg.txt"
	output:
		read_bins = "search/local_e{er}.gff"
	threads: search_threads
	params:
		e = get_search_error_count
	shell:
		"""
		( /usr/bin/time -a -o valik.time -f "%e\t%M\t%x\tvalik-local-search\t{threads}" valik search --time --shared-memory --cart_max_capacity {cart_capacity} --max_queued_carts {queued_carts} --index {input.ibf} --ref-meta {input.ref_meta} --seg-meta {input.seg_meta} --query {input.query} --error {params.e} --pattern {pattern} --overlap {overlap} --threads {threads} --output {output.read_bins})
		"""

rule valik_local_consolidate:
	input:
		alignment = "search/local_e{er}.gff",
		ref_meta = "split/ref.txt",
		seg_meta = "split/seg.txt"
	output:
		"search/consolidated_local_e{er}.gff"
	threads: 1
	params:
		e = get_search_error_count
	shell:
		"""
		( /usr/bin/time -a -o valik.time -f "%e\t%M\t%x\tvalik-local-consolidate\t{threads}" valik consolidate --input {input.alignment} --ref-meta {input.ref_meta} --output {output})
		"""

