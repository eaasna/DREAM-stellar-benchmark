Threshold 32 for 0 errors
Threshold 13 for 1 errors
Threshold 8 for 2 errors
Threshold 6 for 3 errors
Threshold 5 for 4 errors
Threshold 5 for 5 errors
shape = "1110100101001101111"

#------ Simulation parameters ------
reference_length: 262144000 # should ref_len always == query_len?
query_length: 262144000
match_count: 131073 # (1024 / 2000) < 1 match per query file

#------ DREAM parameters ------
ibf_bins: 4096
cart_max_capacity: 500
max_queued_carts: 4096
seg_count: 26000

#------ Stellar parameters ------
num_matches: 131073
sort_threshold: 131074

#------ Evaluation parameters ------
repeat: 1
