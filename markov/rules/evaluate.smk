rule dream_accuracy:
	input:
		truth = "dist_stellar/rep{rep}_e{er}.gff",
		search = "valik/rep{rep}_e{er}_a{ac}_n{en}_cart"+ str(cart_capacities[0]) +"_queue" + str(queue_capacities[0]) + ".gff", 
		ref_meta = data_dir + "ref/rep{rep}_e{er}.bin"
	output:
		"evaluation/valik_rep{rep}_e{er}_a{ac}_n{en}.tsv"
	shell:
		"{script_dir}/search_accuracy.sh {input.truth} {input.search} {min_len} {min_overlap} {input.ref_meta} {output}"

rule valik_table1:
	input:
                benchmark = expand("benchmarks/valik_rep{rep}_e{er}_a{ac}_n{en}_cart" + str(cart_capacities[0]) + "_queue" + str(queue_capacities[0]) + ".txt", rep=repetitions, er=error_rates, ac = adapt_cutoffs, en = entropy_cutoffs),
                evaluation = expand("evaluation/valik_rep{rep}_e{er}_a{ac}_n{en}_cart" + str(cart_capacities[0]) + "_queue" + str(queue_capacities[0]) + ".tsv", rep=repetitions, er=error_rates, ac = adapt_cutoffs, en = entropy_cutoffs)
	output:
		"valik_table1.tsv"
	params:
		repeats = n,	# set as parameters to use in .py,
		error_rates = error_rates,
		adapt_cutoffs = adapt_cutoffs,
		entropy_cutoffs = entropy_cutoffs
	script:
		"../scripts/make_table.py"

