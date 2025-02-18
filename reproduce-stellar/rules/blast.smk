blast_log = "blast.time"
f = open("blast.time", "a")
f.write("time\tmem\texit-code\tcommand\tthreads\tevalue\tkmer-size\tmatches\n")
f.close()

rule blast_index:
	input:
		data_dir + "ref_rep{rep}.fasta"
	output: 
		"/dev/shm/ref_rep{rep}.fasta.ndb"
	benchmark:
		"benchmarks/blast_build_rep{rep}.txt"
	threads: workflow.cores
	shell:
		"""
		( /usr/bin/time -a -o {blast_log} -f "%e\t%M\t%x\tblast-db\t{threads}"	makeblastdb -dbtype nucl -in {input})
		"""

def blast_kmer_size(wildcards):
	errors = round(int(min_len) * float(wildcards.er))
	for k in range(51, 6, -1):
		if ((int(min_len) - k + 1 - errors * k ) > 2 ):
			return k

rule blast_default_search:
	input:
		ref = data_dir + "ref_rep{rep}.fasta",
		db = "/dev/shm/ref_rep{rep}.fasta.ndb",
		query = data_dir + "query/rep{rep}_e{er}.fasta"
	output:
		"blast_default/rep{rep}_e{er}.bed"
	threads: workflow.cores
	benchmark:
		"benchmarks/blast_default_rep{rep}_e{er}.txt"
	shell:
		"""
		mkdir -p blast
		( timeout 12h /usr/bin/time -a -o {blast_log} -f "%e\t%M\t%x\tblast-seach\t{threads}\t{default_evalue}\t{default_k}"	blastn -db {input.ref} -query {input.query} -evalue {default_evalue} -word_size {default_k} -outfmt "6 sseqid sstart send pident sstrand evalue qseqid qstart qend" -out {output} || touch {output} )
		
		truncate -s -1 {blast_log}
		wc -l {output} | awk '{{ print "\t" $1 }}' >> {blast_log}
		"""
		
rule blast_search:
	input:
		ref = data_dir + "ref_rep{rep}.fasta",
		db = "/dev/shm/ref_rep{rep}.fasta.ndb",
		query = data_dir + "query/rep{rep}_e{er}.fasta"
	output:
		"blast/rep{rep}_e{er}.bed"
	params:
		k = get_blast_word_size
	threads: workflow.cores
	benchmark:
		"benchmarks/blast_rep{rep}_e{er}.txt"
	shell:
		"""
		mkdir -p blast
		( timeout 12h /usr/bin/time -a -o {blast_log} -f "%e\t%M\t%x\tblast-seach\t{threads}\t{default_evalue}\t{params.k}"	blastn -db {input.ref} -query {input.query} -evalue {default_evalue} -word_size {params.k} -outfmt "6 sseqid sstart send pident sstrand evalue qseqid qstart qend" -out {output} || touch {output} )

		truncate -s -1 {blast_log}
		wc -l {output} | awk '{{ print "\t" $1 }}' >> {blast_log}
		"""
