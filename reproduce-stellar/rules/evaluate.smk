rule stellar_accuracy:
	input:
		search = "stellar/rep{rep}_e{er}.gff",
		truth = "ground_truth/rep{rep}_e{er}.tsv"
	output:
		"evaluation/stellar_rep{rep}_e{er}.tsv"
	shell:
		"""
		echo -e "total_match_count\ttrue_match_count\tmissed" > {output}
		wc -l {input.search} | awk '{{ print $1 "\t" $1 "\t0"}}' >> {output}
		"""

rule stellar_table1:
	input:
                benchmark = expand("benchmarks/stellar_rep{rep}_e{er}.txt", rep=repetitions, er=error_rates),
                evaluation = expand("evaluation/stellar_rep{rep}_e{er}.tsv", rep=repetitions, er=error_rates)
	output:
		"stellar_table1.tsv"
	params:
		repeats = n,	# set as parameters to use in .py
		prefix = "stellar",
		error_rates = error_rates
	script:
		"../scripts/make_stellar_table1.py"

rule dream_accuracy:
	input:
		truth = "stellar/rep{rep}_e{er}.gff",
		search = "valik/rep{rep}_e{er}.gff",
		ref_meta = "meta/ref_rep{rep}_e{er}.bin"
	output:
		"evaluation/valik_rep{rep}_e{er}.tsv"
	shell:
		script_dir + "/search_accuracy.sh {input.truth} {input.search} {min_len} {min_overlap} {input.ref_meta} {output}"

rule valik_table1:
	input:
                benchmark = expand("benchmarks/valik_rep{rep}_e{er}.txt", rep=repetitions, er=error_rates),
                evaluation = expand("evaluation/valik_rep{rep}_e{er}.tsv", rep=repetitions, er=error_rates)
	output:
		"valik_table1.tsv"
	params:
		repeats = n,	# set as parameters to use in .py,
		prefix = "valik",
		error_rates = error_rates
	script:
		"../scripts/make_stellar_table1.py"

rule blast_accuracy:
	input:
		search = "blast/rep{rep}_e{er}.bed",
		truth = "stellar/rep{rep}_e{er}.gff",
		ref_meta = "meta/ref_rep{rep}_e{er}.bin"
	output:
		"evaluation/blast_rep{rep}_e{er}.tsv"
	shell:
		script_dir + "/search_accuracy.sh {input.truth} {input.search} {min_len} {min_overlap} {input.ref_meta} {output}"

rule blast_table1:
	input:
                benchmark = expand("benchmarks/blast_rep{rep}_e{er}.txt", rep=repetitions, er=error_rates),
                evaluation = expand("evaluation/blast_rep{rep}_e{er}.tsv", rep=repetitions, er=error_rates)
	output:
		"blast_table1.tsv"
	params:
		repeats = n,	# set as parameters to use in .py
		prefix = "blast",
		error_rates = error_rates
	script:
		"../scripts/make_stellar_table1.py"

rule blast_default_accuracy:
	input:
		search = "blast_default/rep{rep}_e{er}.bed",
		truth = "stellar/rep{rep}_e{er}.gff",
		ref_meta = "meta/ref_rep{rep}_e{er}.bin"
	output:
		"evaluation/blast_default_rep{rep}_e{er}.tsv"
	shell:
		script_dir + "/search_accuracy.sh {input.truth} {input.search} {min_len} {min_overlap} {input.ref_meta} {output}"

rule blast_default_table1:
	input:
                benchmark = expand("benchmarks/blast_default_rep{rep}_e{er}.txt", rep=repetitions, er=error_rates),
                evaluation = expand("evaluation/blast_default_rep{rep}_e{er}.tsv", rep=repetitions, er=error_rates)
	output:
		"blast_default_table1.tsv"
	params:
		repeats = n,	# set as parameters to use in .py
		prefix = "blast_default",
		error_rates = error_rates
	script:
		"../scripts/make_stellar_table1.py"

rule last_accuracy:
	input:
		search = "last/rep{rep}_e{er}.bed",
		truth = "stellar/rep{rep}_e{er}.gff",
		ref_meta = "meta/ref_rep{rep}_e{er}.bin"
	output:
		"evaluation/last_rep{rep}_e{er}.tsv"
	shell:
		script_dir + "/search_accuracy.sh {input.truth} {input.search} {min_len} {min_overlap} {input.ref_meta} {output}"

rule last_table1:
	input:
                benchmark = expand("benchmarks/last_rep{rep}_e{er}.txt", rep=repetitions, er=error_rates),
                evaluation = expand("evaluation/last_rep{rep}_e{er}.tsv", rep=repetitions, er=error_rates)
	output:
		"last_table1.tsv"
	params:
		repeats = n,	# set as parameters to use in .py
		prefix = "last",
		error_rates = error_rates
	script:
		"../scripts/make_stellar_table1.py"

rule lastz_accuracy:
	input:
		search = "lastz/rep{rep}_e{er}.gff",
		truth = "stellar/rep{rep}_e{er}.gff",
		ref_meta = "meta/ref_rep{rep}_e{er}.bin"
	output:
		"evaluation/lastz_rep{rep}_e{er}.tsv"
	shell:
		script_dir + "/search_accuracy.sh {input.truth} {input.search} {min_len} {min_overlap} {input.ref_meta} {output}"

rule lastz_table1:
	input:
                benchmark = expand("benchmarks/lastz_rep{rep}_e{er}.txt", rep=repetitions, er=error_rates),
                evaluation = expand("evaluation/lastz_rep{rep}_e{er}.tsv", rep=repetitions, er=error_rates)
	output:
		"lastz_table1.tsv"
	params:
		repeats = n,	# set as parameters to use in .py
		prefix = "last",
		error_rates = error_rates
	script:
		"../scripts/make_stellar_table1.py"
