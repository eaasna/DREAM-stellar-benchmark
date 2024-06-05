import pandas as pd


# ------- INPUT --------
#n = 1
#prefix = "blast"
n = snakemake.params.repeats
prefix = snakemake.params.prefix

# ------- OUTPUT ------- 
table = snakemake.output[0]
#table = "blast_table1_test.tsv"

error_rate_list = snakemake.params.error_rates
#error_rate_list = [0.05]
import pandas as pd

dfs = []
for rep in range(n):
    search_time_list = []
    build_time_list = []
    #missed_list = []
    total_match_list = []
    for er in error_rate_list:
        search_benchmark_file = "benchmarks/" + prefix + "_e" + str(er) + "_b" + str(snakemake.wildcards.b) + ".txt"
        search_benchmark = pd.read_csv(search_benchmark_file, sep='\t')
        search_time_list.append(round(search_benchmark['s'].iloc[0], 3))

        if (prefix != "stellar"):
            build_benchmark_file = "benchmarks/" + prefix + "_build_b" + str(snakemake.wildcards.b) + ".txt"
            print(build_benchmark_file)
            build_benchmark = pd.read_csv(build_benchmark_file, sep='\t')
            build_time_list.append(round(build_benchmark['s'].iloc[0], 3))        
        
        evaluation_file = "evaluation/" + prefix + "_e" + str(er) + "_b" + str(snakemake.wildcards.b) + ".tsv"
        evaluation = pd.read_csv(evaluation_file, sep='\t')
        #missed_list.append(round(evaluation["missed"].iloc[0], 3))
        total_match_list.append(int(evaluation["true_match_count"].iloc[0]))

    if (prefix != "stellar"): 
        data = {'error_rate':error_rate_list,
                'build time (sec)':build_time_list,
                'search time (sec)':search_time_list,
                #'missed (%)':missed_list}
                'match_count':total_match_list}
    else:    
        data = {'error_rate':error_rate_list,
                'search time (sec)':search_time_list,
                #'missed (%)':missed_list}
                'match_count':total_match_list}

    
    dfs.append(pd.DataFrame(data))
    
# find mean of each time and missed cell over all repetitions
rep_mean = pd.concat(dfs).groupby(level=0).mean()
rep_mean = rep_mean.round(3)
rep_mean.to_csv(table, sep='\t')