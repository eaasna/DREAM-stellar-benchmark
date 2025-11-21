rule simulate_sequences:
	input:
		ref = "/srv/data/evelina/mouse/dna4.fasta"
	output:
		ref = data_dir + "large_rep{rep}.fasta",
		query = data_dir + "small_rep{rep}.fasta"
	params:
		ref_seed = get_seed,
		query_seed = get_seed
	shell:
		"{script_dir}/simulate_sequences.sh {input.ref} {output.ref} {output.query} {ref_len} {query_len} {params.ref_seed} {params.query_seed} {order}"

rule simulate_matches:
	input:
		data_dir + "large_rep{rep}.fasta",
		data_dir + "small_rep{rep}.fasta"
	output:
		data_dir + "ref/rep{rep}_e{er}.fasta",
		data_dir + "local_matches/rep{rep}_e{er}.fasta",
		data_dir + "ground_truth/rep{rep}_e{er}.tsv"
	params:
		seed = get_seed
	shell:      
		"{script_dir}/simulate_local_matches.sh {wildcards.rep} {data_dir} {min_len} {max_len} {ref_len} {wildcards.er} {matches} {params.seed}"

