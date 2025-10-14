f = open("blast.time", "a")
f.write("#### PARAMS ####\n")
for par in config:
	f.write(par + '\t' + str(config[par]) + '\n')
f.write("#### LOG ####\n")
f.write("Time\tMemory\tExitcode\tCommand\tThreads\tError rate\tQuery length\n")
f.close()

rule blast_index:
	input:
		"dmel.fasta"
	output: 
		"dmel.fasta.ndb"
	benchmark:
		"benchmarks/blast_index.txt"
	shell:
		"""
		( /usr/bin/time -a -o blast.time -f "%e\t%M\t%x\tblast-index\t{threads}"	makeblastdb -dbtype nucl -in {input})
		"""

rule blast_search:
	input:
		ref = "dmel.fasta",
		db = "dmel.fasta.ndb",
		query = "reads_rep{rep}_e{er}_l{len}/dmel.fasta"
	output:
		"blast/rep{rep}_e{er}_l{len}.tsv"
	benchmark:
		"benchmarks/blast_rep{rep}_e{er}_l{len}.txt"
	shell:
		"""
		mkdir -p blast
		( /usr/bin/time -a -o blast.time -f "%e\t%M\t%x\tblast-search\t{threads}\t{wildcards.er}\t{wildcards.len}"	blastn -db {input.ref} -query {input.query} -outfmt "6 sseqid sstart send pident sstrand evalue qseqid qstart qend" -out {output})
		"""

