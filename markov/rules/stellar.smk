stellar_log = "stellar.time"
f = open(stellar_log, "a")
f.write("time\tmem\texit-code\tcommand\tthreads\terror-rate\tmatches\n")
f.close()

rule distribute_stellar:
	input:
		index = data_dir + "ref/rep{rep}_e{er}.index",
		query = data_dir + "small_rep{rep}.fasta"
	output: 
		"dist_stellar/rep{rep}_e{er}.gff"
	threads: workflow.cores
	benchmark:
		"benchmarks/dist_stellar_rep{rep}_e{er}.txt"
	shell:
		"""	
		(/usr/bin/time -a -o {stellar_log} -f "%e\t%M\t%x\t%C\t{threads}\t{wildcards.er}" \
			dream-stellar search  --split-query --verbose --bin-cutoff 1.0 --bin-entropy-cutoff 1.0 \
				--numMatches {num_matches} --sortThresh {sort_thresh} --time \
				--index {input.index} --query {input.query} \
				--error-rate {wildcards.er} --threads {threads} --output {output} \
				--stellar-only &> {output}.err)
		
		truncate -s -1 {stellar_log}
		wc -l {output} | awk '{{ print $1 }}' >> {stellar_log}
		"""

rule stellar:
	input:
		ref = data_dir + "ref_rep{rep}.fasta",
		query = data_dir + "query/rep{rep}_e{er}.fasta"
	output: 
		"stellar/rep{rep}_e{er}.gff"
	threads: workflow.cores
	benchmark:
		"benchmarks/stellar_rep{rep}_e{er}.txt"
	shell:
		"""
		( timeout 12h /usr/bin/time -a -o {stellar_log} -f "%e\t%M\t%x\tstellar-search\t1\t{wildcards.er}" stellar --time -a dna --numMatches {num_matches}  --sortThresh {sort_thresh} {input.ref} {input.query} -e {wildcards.er} -l {min_len} -o {output} 2> {output}.err || touch {output} )
		
		truncate -s -1 {stellar_log}
		wc -l {output} | awk '{{ print $1 }}' >> {stellar_log}
		"""
		
