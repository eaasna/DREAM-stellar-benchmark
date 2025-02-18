rule simulate_sequences:
	output:
		ref = data_dir + "ref_rep{rep}.fasta",
		query = temp(data_dir + "random_rep{rep}.fasta")
	params:
		ref_seed = get_seed,
		query_seed = get_seed
	shell:      
		"{script_dir}/simulate_sequences.sh {output.ref} {output.query} {ref_len} {query_len} {params.ref_seed} {params.query_seed}"

rule simulate_matches:
	input:
		ref = data_dir + "ref_rep{rep}.fasta",
		query = data_dir + "random_rep{rep}.fasta"
	output:
		query = data_dir + "query/rep{rep}_e{er}.fasta",
		matches = data_dir + "local_matches/rep{rep}_e{er}.fasta",
		truth = data_dir + "ground_truth/rep{rep}_e{er}.tsv"
	params:
		seed = get_seed
	shell:      
		"{script_dir}/simulate_local_matches.sh {wildcards.rep} {data_dir} {min_len} {max_len} {ref_len} {wildcards.er} {matches} {params.seed}"

