import pandas as pd


# ------- INPUT --------
#n = 1
#prefix = "blast"
n = snakemake.params.repeats
prefix = "valik"

# ------- OUTPUT ------- 
table = snakemake.output[0]
#table = "blast_table1_test.tsv"

error_rate_list = snakemake.params.error_rates
adapt_cutoffs_list = snakemake.params.adapt_cutoffs
entropy_cutoffs_list = snakemake.params.entropy_cutoffs
suffix = snakemake.params.suffix
#error_rate_list = [0.05]
import pandas as pd

log_build_time=False
dfs = []
for rep in range(n):
    search_time_list = []
    build_time_list = []
    missed_list = []
    repeat_queries_list = []
    repeat_lookups_list = []
    for er in error_rate_list:
        print(er)
        for ac in adapt_cutoffs_list:
            for en in entropy_cutoffs_list:
                search_benchmark_file = "benchmarks/" + prefix + "_rep" + str(rep) + "_e" + str(er) +  "_a" + str(ac) + "_n" + str(en) + suffix + ".txt"
                search_benchmark = pd.read_csv(search_benchmark_file, sep='\t')
                search_time_list.append(round(search_benchmark['s'].iloc[0], 3))

                if (log_build_time):
                    build_benchmark_file = "benchmarks/" + prefix + "_build_rep" + str(rep) + "_e" + str(er) + "_a" + str(ac) + "_n" + str(en) + suffix + ".txt"
                    print(build_benchmark_file)
                    build_benchmark = pd.read_csv(build_benchmark_file, sep='\t')
                    build_time_list.append(round(build_benchmark['s'].iloc[0], 3))        
        
                evaluation_file = "evaluation/" + prefix + "_rep" + str(rep) + "_e" + str(er) + "_a" + str(ac) + "_n" + str(en) + suffix + ".tsv"
                evaluation = pd.read_csv(evaluation_file, sep='\t', index_col = 0)
                missed_list.append(round(evaluation["missed"].iloc[0], 3))
                repeat_queries_list.append(evaluation["repeat_queries"].iloc[0])
                repeat_lookups_list.append(evaluation["repeat_lookups"].iloc[0])

    error_table_list= [val for val in error_rate_list for _ in list(range(len(adapt_cutoffs_list)*len(entropy_cutoffs_list)))]
    adapt_table_list = adapt_cutoffs_list*len(error_rate_list)
    adapt_table_list = [val for val in adapt_table_list for _ in list(range(len(entropy_cutoffs_list)))]
    if (log_build_time): 
        data = {'error_rate':error_table_list,
                'adapt_cutoff':adapt_table_list, 
                'entropy_cutoff':entropy_cutoffs_list*len(adapt_cutoffs_list)*len(error_rate_list),
                'build time (sec)':build_time_list,
                'search time (sec)':search_time_list,
                'repeat queries': repeat_queries_list,
                'repeat lookups': repeat_lookups_list,
                'missed (%)':missed_list}
    else:    
        data = {'error_rate':error_table_list,
                'adapt_cutoff':adapt_table_list, 
                'entropy_cutoff':entropy_cutoffs_list*len(adapt_cutoffs_list)*len(error_rate_list),
                'search time (sec)':search_time_list,
                'repeat queries': repeat_queries_list,
                'repeat lookups': repeat_lookups_list,
                'missed (%)':missed_list}
    
    dfs.append(pd.DataFrame(data))
    
# find mean of each time and missed cell over all repetitions
rep_mean = pd.concat(dfs).groupby(level=0).mean()
rep_mean = rep_mean.round(3)
rep_mean['repeat queries'] = rep_mean['repeat queries'].astype(int)
rep_mean['repeat lookups'] = rep_mean['repeat lookups'].astype(int)
rep_mean.to_csv(table, sep='\t')
