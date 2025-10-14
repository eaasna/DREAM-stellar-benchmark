f = open(dream_out + "/build_valik.time", "a")
f.write("time\tmem\terror-code\tcommand\tcommit\tbins\tfpr\tmax-er\tmin-len\tthreads\tminimiser\tcmin\tcmax\tibf-size\n")
f.close()

f = open(dream_out + "/search_valik.time", "a")
f.write("time\tmem\terror-code\tcommand\tcommit\tbins\tseg-count\tfpr\tmin-len\tthreads\tminimiser\tcmin\tcmax\terror-rate\trepeat-flag\tbin-entropy-cutoff\tcart-max-cap\tmax-carts\trepeats\tmatches\n")
f.close()

rule valik_build:
	input:
		ref = dir_path(config["ref"]) + "dna4.fasta",
	output: 
		index = temp("/dev/shm/" + dream_out + "/b{b}_l{min_len}_cmin{cmin}_cmax{cmax}.index"),
		meta = "/dev/shm/" + dream_out + "/b{b}_l{min_len}_cmin{cmin}_cmax{cmax}.bin"
	params: 
		log = dream_out + "/build_valik.time",
		meta = dream_out + "/meta.err",
		is_minimiser = "yes" if minimiser_flag == "--fast" else "no",
		er_rate = get_max_error_rate
	threads: workflow.cores
	shell:
		"""
		( /usr/bin/time -a -o {params.log} -f "%e\t%M\t%x\tvalik-build\t{wildcards.b}\t{fpr}\t{params.er_rate}\t{wildcards.min_len}\t{workflow.cores}\t{params.is_minimiser}\t{wildcards.cmin}\t{wildcards.cmax}" \
			{valik} build {input.ref} {minimiser_flag} --verbose -n {wildcards.b} \
				--error-rate {params.er_rate} --pattern {wildcards.min_len} \
				--threads {threads} --output {output.index} --fpr {fpr} \
				--kmer-count-min {wildcards.cmin} \
				--kmer-count-max {wildcards.cmax} &> {params.meta})
		truncate -s -1 {params.log}
		ls -lh {output} | awk '{{print "\t" $5}}' >> {params.log}

		rm /dev/shm/{dream_out}/dna4.*.minimiser
		rm /dev/shm/{dream_out}/dna4.*.header
		"""

rule valik_search:
	input:
		ibf = "/dev/shm/" + dream_out + "/b{b}_l{min_len}_cmin{cmin}_cmax{cmax}.index",
		query = dir_path(config["query"]) + "dna4.fasta"
	output:
		dream_out + "/b{b}_l{min_len}_cmin{cmin}_cmax{cmax}_e{er}_ent{bin_ent}_cap{max_cap}_carts{max_carts}.gff"
	threads: search_threads
	params:
		log = dream_out + "/search_valik.time",
		is_minimiser = "yes" if minimiser_flag == "--fast" else "no",
		er_rate = get_error_rate
	shell:
		"""
		exec_dir=$(dirname {valik})
		echo $exec_dir
		commit_id=$(cd $exec_dir; cat version.md)
		
		(timeout 24h /usr/bin/time -a -o {params.log} -f \
			"%e\t%M\t%x\tvalik-search\t$commit_id\t{wildcards.b}\t{seg_count}\t{fpr}\t{wildcards.min_len}\t{threads}\t{params.is_minimiser}\t{wildcards.cmin}\t{wildcards.cmax}\t{wildcards.er}\t{repeat_flag}\t{wildcards.bin_ent}\t{wildcards.max_cap}\t{wildcards.max_carts}" \
			{valik} search --bin-entropy-cutoff {wildcards.bin_ent} \
			 	--split-query --cache-thresholds --numMatches {num_matches} \
				--sortThresh {sort_thresh} --index {input.ibf} \
				--query {input.query} --error-rate {params.er_rate} --threads {workflow.cores} \
				--output {output} --cart-max-capacity {wildcards.max_cap} \
				--max-queued-carts {wildcards.max_carts} \
				--seg-count {seg_count} &> {output}.search.err)

		truncate -s -1 {params.log}
		# grep fails in bash strict mode if no matches found
		{{ grep Insufficient {output}.search.err || test $? = 1; }} | wc -l | awk '{{ print "\t" $1}}' >> {params.log}

		truncate -s -1 {params.log}
		wc -l {output} | awk '{{ print "\t" $1}}' >> {params.log}
		"""

rule valik_shape_build:
	input:
		ref = dir_path(config["ref"]) + "dna4.fasta",
	output: 
		index = temp("/dev/shm/" + dream_out + "/b{b}_l{min_len}_s{s}_cmin{cmin}_cmax{cmax}.index"),
		meta = "/dev/shm/" + dream_out + "/b{b}_l{min_len}_s{s}_cmin{cmin}_cmax{cmax}.bin"
	params: 
		log = dream_out + "/build_valik.time",
		meta = dream_out + "/meta.err",
		is_minimiser = "yes" if minimiser_flag == "--fast" else "no",
		er_rate = get_max_error_rate
	threads: workflow.cores
	shell:
		"""
		( /usr/bin/time -a -o {params.log} -f "%e\t%M\t%x\tvalik-build\t{wildcards.b}\t{fpr}\t{params.er_rate}\t{wildcards.min_len}\t{wildcards.s}\t{workflow.cores}\t{params.is_minimiser}\t{wildcards.cmin}\t{wildcards.cmax}" \
			{valik} build {input.ref} {minimiser_flag} --verbose -n {wildcards.b} \
				--error-rate {params.er_rate} --pattern {wildcards.min_len} \
				--threads {threads} --output {output.index} --fpr {fpr} \
				--kmer-count-min {wildcards.cmin} --shape {wildcards.s} \
				--kmer-count-max {wildcards.cmax} &> {params.meta})
		truncate -s -1 {params.log}
		ls -lh {output} | awk '{{print "\t" $5}}' >> {params.log}

		rm /dev/shm/{dream_out}/dna4.*.minimiser
		rm /dev/shm/{dream_out}/dna4.*.header
		"""

rule valik_shape_search:
	input:
		ibf = "/dev/shm/" + dream_out + "/b{b}_l{min_len}_s{s}_cmin{cmin}_cmax{cmax}.index",
		query = dir_path(config["query"]) + "dna4.fasta"
	output:
		dream_out + "/b{b}_l{min_len}_s{s}_cmin{cmin}_cmax{cmax}_e{er}_ent{bin_ent}_cap{max_cap}_carts{max_carts}.gff"
	threads: search_threads
	params:
		log = dream_out + "/search_valik.time",
		is_minimiser = "yes" if minimiser_flag == "--fast" else "no",
		er_rate = get_error_rate,
	shell:
		"""
		exec_dir=$(dirname {valik})
		echo $exec_dir
		commit_id=$(cd $exec_dir; cat version.md)
		
		(timeout 24h /usr/bin/time -a -o {params.log} -f \
			"%e\t%M\t%x\tvalik-search\t$commit_id\t{wildcards.b}\t{seg_count}\t{fpr}\t{wildcards.min_len}\t{wildcards.s}\t{threads}\t{params.is_minimiser}\t{wildcards.cmin}\t{wildcards.cmax}\t{wildcards.er}\t{repeat_flag}\t{wildcards.bin_ent}\t{wildcards.max_cap}\t{wildcards.max_carts}" \
			{valik} search --bin-entropy-cutoff {wildcards.bin_ent} \
			 	--split-query --cache-thresholds --numMatches {num_matches} \
				--sortThresh {sort_thresh} --index {input.ibf} \
				--query {input.query} --error-rate {params.er_rate} --threads {workflow.cores} \
				--output {output} --cart-max-capacity {wildcards.max_cap} \
				--max-queued-carts {wildcards.max_carts} \
				--seg-count {seg_count} &> {output}.search.err)

		truncate -s -1 {params.log}
		# grep fails in bash strict mode if no matches found
		{{ grep Insufficient {output}.search.err || test $? = 1; }} | wc -l | awk '{{ print "\t" $1}}' >> {params.log}

		truncate -s -1 {params.log}
		wc -l {output} | awk '{{ print "\t" $1}}' >> {params.log}
		"""

