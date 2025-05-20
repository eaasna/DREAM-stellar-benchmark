stellar_log = stellar_out + "/stellar.time"
f = open(stellar_log, "a")
f.write("time\tmem\terror-code\tcommand\tmin-len\terror-rate\trepeat-period\trepeat-length\tmatches\n")
f.close()

rule stellar:
	input:
		ref = ancient(dir_path(config["ref"]) + "dna4.fasta"),
		query = ancient(dir_path(config["query"]) + "dna4.fasta")
	output: 
		stellar_out + "/" + run_id + "_l{min_len}_e{er}_rp{rp}_rl{rl}.gff"
	threads: 1
	params: 
		er_rate = get_error_rate
	shell:
		"""
		(timeout 24h /usr/bin/time -a -o {stellar_log} -f "%e\t%M\t%x\tstellar-search\t{wildcards.min_len}\t{params.er_rate}\t{wildcards.rp}\t{wildcards.rl}" \
			{stellar} -a dna --numMatches {num_matches} \
				--sortThresh {sort_thresh} {input.ref} {input.query} -e {params.er_rate} \
				-l {wildcards.min_len} --repeatPeriod {wildcards.rp} \
				--repeatLength {wildcards.rl} -o {output} 2> {output}.err || touch {output})

		truncate -s -1 {stellar_log}
		wc -l {output} | awk '{{print "\t" $1}}' >> {stellar_log}
		"""

dist_stellar_log = dist_stellar_out + "/dist_stellar.time"
f = open(dist_stellar_log, "a")
f.write("time\tmem\terror-code\tcommand\tmin-len\terror-rate\tthreads\tmatches\n")
f.close()

rule distribute_stellar:
	input:
		ref_meta = expand(dream_out + "/meta/b{b}_fpr{fpr}_l{{min_len}}_e{{er}}_s{s}.bin", b = bin_list[0], fpr = fpr_list[0], s = valik_shapes[0]),
		query = ancient(dir_path(config["query"]) + "dna4.fasta")
	output: 
		"dist_" + stellar_out + "/" + run_id + "_l{min_len}_e{er}_rp{rp}_rl{rl}.gff"
	threads: workflow.cores
	params: 
		er_rate = get_error_rate
	shell:
		"""	
		(timeout 24h /usr/bin/time -a -o {dist_stellar_log} -f "%e\t%M\t%x\t%C\t{threads}\t{wildcards.min_len}\t{wildcards.er}\t{threads}" \
			{valik} search  --split-query --verbose \
				--numMatches {num_matches} --sortThresh {sort_thresh} --time \
				--ref-meta {input.ref_meta} --query {input.query} \
				--error-rate {params.er_rate} --threads {threads} --output {output} \
				--stellar-only &> {output}.err)
		
		truncate -s -1 {dist_stellar_log}
		wc -l {output} | awk '{{ print $1 }}' >> {dist_stellar_log}
		"""

