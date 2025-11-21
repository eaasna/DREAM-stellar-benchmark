valik_build_log="valik_build.time"
f = open(valik_build_log, "a")
f.write("time\tmem\texit-code\tcommand\tthreads\tbins\tfpr\terror-rate\tmin-len\tibf_size\n")
f.close()
rule valik_build:
	input:
		ref = data_dir + "ref_rep{rep}.fasta"
	output:
		index = data_dir + "ref_rep{rep}.index",
		meta = data_dir + "ref_rep{rep}.bin",
		arg = data_dir + "ref_rep{rep}.arg"	
	threads: workflow.cores
	params:
		log = data_dir + "ref_rep{rep}.build.err"
	benchmark:
		"benchmarks/valik_build_rep{rep}.txt"
	shell:
		"""
		( /usr/bin/time -a -o {valik_build_log} -f "%e\t%M\t%x\t%C\t{threads}\t{bins}\t{fpr}\t{max_er}\t{min_len}" valik build {input.ref} --error-rate {max_er} -n {bins} --fpr {fpr} --pattern {min_len} --threads {threads} --output {output.index} --verbose &> {params.log})
 
		truncate -s -1 {valik_build_log}
		ls -lh {output} | awk '{{ print "\t" $5 }}' >> {valik_build_log}
		"""

valik_search_log="valik_search.time"
f = open(valik_search_log, "a")
f.write("time\tmem\texit-code\tcommand\tthreads\tbins\tadapt-cutoff\tentropy-cutoff\terror-rate\tmin-len\tmatches\n")
f.close()
rule valik_search:
	input:
		ibf = data_dir + "ref_rep{rep}.index",
		query = data_dir + "query/rep{rep}_e{er}.fasta",
	output:
		"valik/rep{rep}_e{er}_a{ac}_n{ec}.gff"
	threads: workflow.cores
	benchmark: 
		"benchmarks/valik_rep{rep}_e{er}_a{ac}_n{ec}.txt"
	shell:
		"""
		(/usr/bin/time -a -o {valik_search_log} -f "%e\t%M\t%x\t%C\t{threads}\t{bins}\{wildcards.ac}\t{wildcards.ec}\t{wildcards.er}\t{min_len}\t" \
			valik search --bin-cutoff {wildcards.ac} --bin-entropy-cutoff {wildcards.ec} \
				--split-query --cache-thresholds --verbose \
				--numMatches {num_matches} --sortThresh {sort_thresh} --time \
				--index {input.ibf} --query {input.query} \
				--error-rate {wildcards.er} --threads {threads} --output {output} \
				--cart-max-capacity {max_capacity} --max-queued-carts {max_carts} \
				--seg-count {seg_count} &> {output}.err)
		
		truncate -s -1 {valik_search_log}
		wc -l {output} | awk '{{ print $1 }}' >> {valik_search_log}
		"""

