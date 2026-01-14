valik_build_log="valik_build.time"
f = open(valik_build_log, "a")
f.write("time\tmem\texit-code\tcommand\tthreads\tbins\tfpr\terror-rate\tmin-len\tibf_size\n")
f.close()
rule index_build:
	input:
		ref = data_dir + "ref/rep{rep}_e{er}.fasta"
	output:
		index = data_dir + "ref/rep{rep}_e{er}.index",
		meta = data_dir + "ref/rep{rep}_e{er}.bin",
		arg = data_dir + "ref/rep{rep}_e{er}.arg"	
	threads: workflow.cores
	params:
		log = data_dir + "ref/rep{rep}_e{er}.build.err"
	benchmark:
		"benchmarks/valik_build_rep{rep}_e{er}.txt"
	shell:
		"""
		( /usr/bin/time -a -o {valik_build_log} -f "%e\t%M\t%x\t%C\t{threads}\t{bins}\t{fpr}\t{max_er}\t{min_len}" \
			dream-stellar build {input.ref} --error-rate {max_er} -n {bins} \
				--fpr {fpr} --pattern {min_len} --shape 11110101011101010111 \
				--threads {threads} \
				--output {output.index} --verbose --fast &> {params.log})
 
		truncate -s -1 {valik_build_log}
		ls -lh {output} | awk '{{ print "\t" $5 }}' >> {valik_build_log}
		"""

valik_search_log="valik_search.time"
f = open(valik_search_log, "a")
f.write("time\tmem\texit-code\tcommand\tthreads\tbins\tadapt-cutoff\tentropy-cutoff\tcart-cap\tqueue-cap\terror-rate\tmin-len\tmatches\trepeat_queries\trepeat_lookups\n")
f.close()
rule query_search:
	input:
		ibf = data_dir + "ref/rep{rep}_e{er}.index",
		query = data_dir + "small_rep{rep}.fasta",
	output:
		"valik/rep{rep}_e{er}_a{ac}_n{ec}_cart{cart_cap}_queue{queue_cap}.gff"
	threads: workflow.cores
	benchmark: 
		"benchmarks/valik_rep{rep}_e{er}_a{ac}_n{ec}_cart{cart_cap}_queue{queue_cap}.txt"
	shell:
		"""
		(/usr/bin/time -a -o {valik_search_log} -f "%e\t%M\t%x\t%C\t{threads}\t{bins}\t{wildcards.ac}\t{wildcards.ec}\t{wildcards.cart_cap}\t{wildcards.queue_cap}\t{wildcards.er}\t{min_len}\t" \
			dream-stellar search --bin-cutoff {wildcards.ac} --bin-entropy-cutoff {wildcards.ec} \
				--split-query --cache-thresholds \
				--numMatches {num_matches} --sortThresh {sort_thresh} --time \
				--index {input.ibf} --query {input.query} \
				--error-rate {wildcards.er} --threads {threads} --output {output} \
				--cart-max-capacity {wildcards.cart_cap} --max-queued-carts {wildcards.queue_cap} \
				--seg-count {seg_count} &> {output}.err)
		
		truncate -s -1 {valik_search_log}
		wc -l {output} | awk '{{ print $1 "\t" }}' >> {valik_search_log}

		truncate -s -1 {valik_search_log}
	
		if grep -q Insufficient {output}.err
		then 
			rep_lines=$(grep Insufficient {output}.err | wc -l | awk '{{print $1}}')
			echo -e "$rep_lines\t" >> {valik_search_log}
		
			truncate -s -1 {valik_search_log}		
			grep Insufficient {output}.err | awk '{{print $4}}' | paste -sd+ | bc >> {valik_search_log}
		else
			echo -e "0\t0" >> {valik_search_log}
		fi
		"""

