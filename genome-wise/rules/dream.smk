f = open(dream_out + "/split_valik.time", "a")
f.write("time\tmem\terror-code\tcommand\tcommit\tbins\tfpr\tmax-er\tmin-len\n")
f.close()

f = open(dream_out + "/build_valik.time", "a")
f.write("time\tmem\terror-code\tcommand\tcommit\tbins\tfpr\tmax-er\tmin-len\tthreads\tminimiser\tcmin\tcmax\tibf-size\n")
f.close()

f = open(dream_out + "/search_valik.time", "a")
f.write("time\tmem\terror-code\tcommand\tcommit\tbins\tseg-count\tfpr\tmax-er\tmin-len\tthreads\tminimiser\tcmin\tcmax\terror-rate\trepeat-flag\tbin-entropy-cutoff\tcart-max-cap\tmax-carts\trepeat-period\trepeat-length\trepeats\tmatches\n")
f.close()

rule valik_split_ref:
	input:
		dir_path(config["ref"]) + "dna4.fasta"
	output: 
		ref_meta = dream_out + "/meta/b{b}_fpr{fpr}_l{min_len}_e{er}.bin"
	params:
		log = dream_out + "/split_valik.time",
		er_rate = get_error_rate
	shell:
		"""
		( /usr/bin/time -a -o {params.log} -f "%e\t%M\t%x\tvalik-split\t{wildcards.b}\t{wildcards.fpr}\t{params.er_rate}\t{wildcards.min_len}" \
			{valik} split {input} --verbose --fpr {wildcards.fpr} --out {output.ref_meta} --kmer 18 \
				--error-rate {params.er_rate}  --pattern {wildcards.min_len} -n {wildcards.b} &> {output}.split.err)
		"""
			#{valik} split {input} --verbose --fpr {wildcards.fpr} --out {output.ref_meta} \

rule valik_build:
	input:
		ref = dir_path(config["ref"]) + "dna4.fasta",
		ref_meta = dream_out + "/meta/b{b}_fpr{fpr}_l{min_len}_e{er}.bin"
	output: 
		temp("/dev/shm/" + dream_out + "/b{b}_fpr{fpr}_l{min_len}_e{er}_cmin{cmin}_cmax{cmax}.index")
	params: 
		log = dream_out + "/build_valik.time",
		is_minimiser = "yes" if minimiser_flag == "--fast" else "no",
		er_rate = get_error_rate
	threads: workflow.cores
	shell:
		"""
		( /usr/bin/time -a -o {params.log} -f "%e\t%M\t%x\tvalik-build\t{wildcards.b}\t{wildcards.fpr}\t{params.er_rate}\t{wildcards.min_len}\t{workflow.cores}\t{params.is_minimiser}\t{wildcards.cmin}\t{wildcards.cmax}" \
			{valik} build {minimiser_flag} --threads {threads} --output {output} \
				--ref-meta {input.ref_meta} --kmer-count-min {wildcards.cmin} \
				--kmer-count-max {wildcards.cmax} 2> {output}.err)
		truncate -s -1 {params.log}
		ls -lh {output} | awk '{{print "\t" $5}}' >> {params.log}

		rm /dev/shm/{dream_out}/dna4.*.minimiser
		rm /dev/shm/{dream_out}/dna4.*.header
		"""

rule valik_search:
	input:
		ibf = "/dev/shm/" + dream_out + "/b{b}_fpr{fpr}_l{min_len}_e{er}_cmin{cmin}_cmax{cmax}.index",
		query = dir_path(config["query"]) + "dna4.fasta",
		ref_meta = dream_out + "/meta/b{b}_fpr{fpr}_l{min_len}_e{er}.bin"
	output:
		dream_out + "/b{b}_fpr{fpr}_l{min_len}_cmin{cmin}_cmax{cmax}_e{er}_ent{bin_ent}_cap{max_cap}_carts{max_carts}_t{t}_rp{rp}_rl{rl}.gff"
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
			"%e\t%M\t%x\tvalik-search\t$commit_id\t{wildcards.b}\t{seg_count}\t{wildcards.fpr}\t{params.er_rate}\t{wildcards.min_len}\t{threads}\t{params.is_minimiser}\t{wildcards.cmin}\t{wildcards.cmax}\t{wildcards.er}\t{repeat_flag}\t{wildcards.bin_ent}\t{wildcards.max_cap}\t{wildcards.max_carts}\t{wildcards.rp}\t{wildcards.rl}" \
			{valik} search {repeat_flag} --bin-entropy-cutoff {wildcards.bin_ent} \
			 	--split-query --cache-thresholds --numMatches {num_matches} \
				--sortThresh {sort_thresh} --index {input.ibf} --ref-meta {input.ref_meta} \
				--query {input.query} --error-rate {params.er_rate} --threads {wildcards.t} \
				--output {output} --cart-max-capacity {wildcards.max_cap} \
				--max-queued-carts {wildcards.max_carts} \
				--verbose --time \
				--repeatPeriod {wildcards.rp} --repeatLength {wildcards.rl} \
				&> {output}.search.err)

		truncate -s -1 {params.log}
		# grep fails in bash strict mode if no matches found
		{{ grep Insufficient {output}.search.err || test $? = 1; }} | wc -l | awk '{{ print "\t" $1}}' >> {params.log}

		truncate -s -1 {params.log}
		wc -l {output} | awk '{{ print "\t" $1}}' >> {params.log}
		"""

rule valik_kmer_split_ref:
	input:
		dir_path(config["ref"]) + "dna4.fasta"
	output: 
		ref_meta = dream_out + "/meta/b{b}_fpr{fpr}_l{min_len}_e{er}_k{k}.bin"
	params:
		log = dream_out + "/split_valik.time",
		er_rate = get_error_rate
	shell:
		"""
		( /usr/bin/time -a -o {params.log} -f "%e\t%M\t%x\tvalik-split\t{wildcards.b}\t{wildcards.fpr}\t{params.er_rate}\t{wildcards.min_len}" \
			{valik} split {input} --verbose --fpr {wildcards.fpr} --out {output.ref_meta} --kmer {wildcards.k} \
				--error-rate {params.er_rate}  --pattern {wildcards.min_len} -n {wildcards.b} &> {output}.split.err)
		"""

rule valik_kmer_build:
	input:
		ref = dir_path(config["ref"]) + "dna4.fasta",
		ref_meta = dream_out + "/meta/b{b}_fpr{fpr}_l{min_len}_e{er}_k{k}.bin"
	output: 
		temp("/dev/shm/" + dream_out + "/b{b}_fpr{fpr}_l{min_len}_e{er}_cmin{cmin}_cmax{cmax}_k{k}.index")
	params: 
		log = dream_out + "/build_valik.time",
		is_minimiser = "yes" if minimiser_flag == "--fast" else "no",
		er_rate = get_error_rate
	threads: workflow.cores
	shell:
		"""
		( /usr/bin/time -a -o {params.log} -f "%e\t%M\t%x\tvalik-build\t{wildcards.b}\t{wildcards.fpr}\t{params.er_rate}\t{wildcards.min_len}\t{wildcards.k}\t{workflow.cores}\t{params.is_minimiser}\t{wildcards.cmin}\t{wildcards.cmax}" \
			{valik} build {minimiser_flag} --threads {threads} --output {output} \
				--ref-meta {input.ref_meta} --kmer-count-min {wildcards.cmin} \
				--kmer-count-max {wildcards.cmax} 2> {output}.err)
		truncate -s -1 {params.log}
		ls -lh {output} | awk '{{print "\t" $5}}' >> {params.log}

		rm /dev/shm/{dream_out}/dna4.*.minimiser
		rm /dev/shm/{dream_out}/dna4.*.header
		"""

rule valik_kmer_search:
	input:
		ibf = "/dev/shm/" + dream_out + "/b{b}_fpr{fpr}_l{min_len}_e{er}_cmin{cmin}_cmax{cmax}_k{k}.index",
		query = dir_path(config["query"]) + "dna4.fasta",
		ref_meta = dream_out + "/meta/b{b}_fpr{fpr}_l{min_len}_e{er}_k{k}.bin"
	output:
		dream_out + "/b{b}_fpr{fpr}_l{min_len}_cmin{cmin}_cmax{cmax}_e{er}_k{k}_ent{bin_ent}_cap{max_cap}_carts{max_carts}_t{t}_rp{rp}_rl{rl}.gff"
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
		
		(/usr/bin/time -a -o {params.log} -f \
			"%e\t%M\t%x\tvalik-search\t$commit_id\t{wildcards.b}\t{seg_count}\t{wildcards.fpr}\t{params.er_rate}\t{wildcards.min_len}\t{wildcards.k}\t{threads}\t{params.is_minimiser}\t{wildcards.cmin}\t{wildcards.cmax}\t{wildcards.er}\t{repeat_flag}\t{wildcards.bin_ent}\t{wildcards.max_cap}\t{wildcards.max_carts}\t{wildcards.rp}\t{wildcards.rl}" \
			{valik} search {repeat_flag} --bin-entropy-cutoff {wildcards.bin_ent} \
			 	--split-query --cache-thresholds --numMatches {num_matches} \
				--sortThresh {sort_thresh} --index {input.ibf} --ref-meta {input.ref_meta} \
				--query {input.query} --error-rate {params.er_rate} --threads {wildcards.t} \
				--output {output} --cart-max-capacity {wildcards.max_cap} \
				--max-queued-carts {wildcards.max_carts} --seg-count {seg_count} 
				--verbose --time \
				--repeatPeriod {wildcards.rp} --repeatLength {wildcards.rl} \
				&> {output}.search.err)

		truncate -s -1 {params.log}
		# grep fails in bash strict mode if no matches found
		{{ grep Insufficient {output}.search.err || test $? = 1; }} | wc -l | awk '{{ print "\t" $1}}' >> {params.log}

		truncate -s -1 {params.log}
		wc -l {output} | awk '{{ print "\t" $1}}' >> {params.log}
		"""

rule valik_kmer_threshold_search:
	input:
		ibf = "/dev/shm/" + dream_out + "/b{b}_fpr{fpr}_l{min_len}_e{er}_cmin{cmin}_cmax{cmax}_k{k}.index",
		query = dir_path(config["query"]) + "dna4.fasta",
		ref_meta = dream_out + "/meta/b{b}_fpr{fpr}_l{min_len}_e{er}_k{k}.bin"
	output:
		dream_out + "/b{b}_fpr{fpr}_l{min_len}_cmin{cmin}_cmax{cmax}_e{er}_k{k}_thresh{thresh}_ent{bin_ent}_cap{max_cap}_carts{max_carts}_t{t}_rp{rp}_rl{rl}.gff"
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
		
		(/usr/bin/time -a -o {params.log} -f \
			"%e\t%M\t%x\tvalik-search\t$commit_id\t{wildcards.b}\t{seg_count}\t{wildcards.fpr}\t{params.er_rate}\t{wildcards.min_len}\t{wildcards.k}\t{wildcards.thresh}\t{threads}\t{params.is_minimiser}\t{wildcards.cmin}\t{wildcards.cmax}\t{wildcards.er}\t{repeat_flag}\t{wildcards.bin_ent}\t{wildcards.max_cap}\t{wildcards.max_carts}\t{wildcards.rp}\t{wildcards.rl}" \
			{valik} search {repeat_flag} --bin-entropy-cutoff {wildcards.bin_ent} \
			 	--split-query --cache-thresholds --numMatches {num_matches} \
				--sortThresh {sort_thresh} --index {input.ibf} --ref-meta {input.ref_meta} \
				--query {input.query} --error-rate {params.er_rate} --threads {threads} \
				--output {output} --cart-max-capacity {wildcards.max_cap} \
				--seg-count {seg_count} --verbose --time \
				--max-queued-carts {wildcards.max_carts} --threshold {wildcards.thresh} \
				--repeatPeriod {wildcards.rp} --repeatLength {wildcards.rl} \
				&> {output}.search.err)

		truncate -s -1 {params.log}
		# grep fails in bash strict mode if no matches found
		{{ grep Insufficient {output}.search.err || test $? = 1; }} | wc -l | awk '{{ print "\t" $1}}' >> {params.log}

		truncate -s -1 {params.log}
		wc -l {output} | awk '{{ print "\t" $1}}' >> {params.log}
		"""

rule valik_shape_split_ref:
	input:
		dir_path(config["ref"]) + "dna4.fasta"
	output: 
		ref_meta = dream_out + "/meta/b{b}_fpr{fpr}_l{min_len}_e{er}_s{s}.bin"
	params:
		log = dream_out + "/split_valik.time",
		er_rate = get_error_rate
	shell:
		"""
		( /usr/bin/time -a -o {params.log} -f "%e\t%M\t%x\tvalik-split\t{wildcards.b}\t{wildcards.fpr}\t{params.er_rate}\t{wildcards.min_len}" \
			{valik} split {input} --verbose --fpr {wildcards.fpr} --out {output.ref_meta} --shape {wildcards.s} \
				--error-rate {params.er_rate}  --pattern {wildcards.min_len} -n {wildcards.b} &> {output}.split.err)
		"""

rule valik_shape_build:
	input:
		ref = dir_path(config["ref"]) + "dna4.fasta",
		ref_meta = dream_out + "/meta/b{b}_fpr{fpr}_l{min_len}_e{er}_s{s}.bin"
	output: 
		"/dev/shm/" + dream_out + "/b{b}_fpr{fpr}_l{min_len}_e{er}_cmin{cmin}_cmax{cmax}_s{s}.index"
	params: 
		log = dream_out + "/build_valik.time",
		is_minimiser = "yes" if minimiser_flag == "--fast" else "no",
		er_rate = get_error_rate
	threads: workflow.cores
	shell:
		"""
		( /usr/bin/time -a -o {params.log} -f "%e\t%M\t%x\tvalik-build\t{wildcards.b}\t{wildcards.fpr}\t{params.er_rate}\t{wildcards.min_len}\t{wildcards.s}\t{workflow.cores}\t{params.is_minimiser}\t{wildcards.cmin}\t{wildcards.cmax}" \
			{valik} build {minimiser_flag} --threads {threads} --output {output} \
				--ref-meta {input.ref_meta} --kmer-count-min {wildcards.cmin} \
				--kmer-count-max {wildcards.cmax} 2> {output}.err)
		truncate -s -1 {params.log}
		ls -lh {output} | awk '{{print "\t" $5}}' >> {params.log}

		rm /dev/shm/{dream_out}/dna4.*.minimiser
		rm /dev/shm/{dream_out}/dna4.*.header
		"""

rule valik_shape_search:
	input:
		ibf = "/dev/shm/" + dream_out + "/b{b}_fpr{fpr}_l{min_len}_e{er}_cmin{cmin}_cmax{cmax}_s{s}.index",
		query = dir_path(config["query"]) + "dna4.fasta",
		ref_meta = dream_out + "/meta/b{b}_fpr{fpr}_l{min_len}_e{er}_s{s}.bin"
	output:
		dream_out + "/b{b}_fpr{fpr}_l{min_len}_cmin{cmin}_cmax{cmax}_e{er}_s{s}_ent{bin_ent}_cap{max_cap}_carts{max_carts}.gff"
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
		
		(/usr/bin/time -a -o {params.log} -f \
			"%e\t%M\t%x\tvalik-search\t$commit_id\t{wildcards.b}\t{seg_count}\t{wildcards.fpr}\t{params.er_rate}\t{wildcards.min_len}\t{wildcards.s}\tN/A\t{threads}\t{params.is_minimiser}\t{wildcards.cmin}\t{wildcards.cmax}\t{wildcards.er}\t{repeat_flag}\t{wildcards.bin_ent}\t{wildcards.max_cap}\t{wildcards.max_carts}\t1\t1000" \
			{valik} search {repeat_flag} --bin-entropy-cutoff {wildcards.bin_ent} \
			 	--split-query --cache-thresholds --numMatches {num_matches} \
				--sortThresh {sort_thresh} --index {input.ibf} --ref-meta {input.ref_meta} \
				--query {input.query} --error-rate {params.er_rate} --threads {threads} \
				--output {output} --cart-max-capacity {wildcards.max_cap} --time --verbose \
				--max-queued-carts {wildcards.max_carts} --seg-count {seg_count} \
				&> {output}.search.err)

		truncate -s -1 {params.log}
		# grep fails in bash strict mode if no matches found
		{{ grep Insufficient {output}.search.err || test $? = 1; }} | wc -l | awk '{{ print "\t" $1}}' >> {params.log}

		truncate -s -1 {params.log}
		wc -l {output} | awk '{{ print "\t" $1}}' >> {params.log}
		"""

rule valik_shape_threshold_search:
	input:
		ibf = "/dev/shm/" + dream_out + "/b{b}_fpr{fpr}_l{min_len}_e{er}_cmin{cmin}_cmax{cmax}_s{s}.index",
		query = dir_path(config["query"]) + "dna4.fasta",
		ref_meta = dream_out + "/meta/b{b}_fpr{fpr}_l{min_len}_e{er}_s{s}.bin"
	output:
		dream_out + "/b{b}_fpr{fpr}_l{min_len}_cmin{cmin}_cmax{cmax}_e{er}_s{s}_ent{bin_ent}_cap{max_cap}_carts{max_carts}_t{t}.gff"
	threads: search_threads
	params:
		log = dream_out + "/search_valik.time",
		is_minimiser = "yes" if minimiser_flag == "--fast" else "no",
		er_rate = get_error_rate,
		thresh = get_shape_threshold
	shell:
		"""
		exec_dir=$(dirname {valik})
		echo $exec_dir
		commit_id=$(cd $exec_dir; cat version.md)
		
		(/usr/bin/time -a -o {params.log} -f \
			"%e\t%M\t%x\tvalik-search\t$commit_id\t{wildcards.b}\t{seg_count}\t{wildcards.fpr}\t{params.er_rate}\t{wildcards.min_len}\t{wildcards.s}\t{params.thresh}\t{threads}\t{params.is_minimiser}\t{wildcards.cmin}\t{wildcards.cmax}\t{wildcards.er}\t{repeat_flag}\t{wildcards.bin_ent}\t{wildcards.max_cap}\t{wildcards.max_carts}\t1\t1000" \
			{valik} search {repeat_flag} --bin-entropy-cutoff {wildcards.bin_ent} \
			 	--split-query --cache-thresholds --numMatches {num_matches} \
				--sortThresh {sort_thresh} --index {input.ibf} --ref-meta {input.ref_meta} \
				--query {input.query} --error-rate {params.er_rate} --threads {threads} \
				--output {output} --cart-max-capacity {wildcards.max_cap} --time \
				--max-queued-carts {wildcards.max_carts} --threshold {params.thresh} \
				--verbose --seg-count {seg_count} &> {output}.search.err)

		truncate -s -1 {params.log}
		# grep fails in bash strict mode if no matches found
		{{ grep Insufficient {output}.search.err || test $? = 1; }} | wc -l | awk '{{ print "\t" $1}}' >> {params.log}

		truncate -s -1 {params.log}
		wc -l {output} | awk '{{ print "\t" $1}}' >> {params.log}
		"""
