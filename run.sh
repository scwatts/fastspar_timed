#!/bin/bash


###
# Options
###
# Print commands as they're executed
set -x

# Required for SparCC to run without thread oversubscription on a single CPU
export OMP_NUM_THREADS=1


###
# Prepare data
###
# Decompress OTU table
gzip -d assets/otu_table_cluster_99_collapsed.tsv.gz

# Generate random subsamples of CAS filtered and reduced OTU table
mkdir random_subsets
parallel -N1 './assets/generate_random_subsets.py -c assets/otu_table_cluster_99_collapsed.tsv -a {1} -t {2} > random_subsets/otu_table_cluster_99_filtered_reduced_random_{1}_{2}.tsv' ::: $(seq 250 250 2500) ::: $(seq 250 250 2500)

# Create some more directories
mkdir output logs


###
# Download programs
###
# SparCC
hg clone https://bitbucket.org/yonatanf/sparcc

# FastSpar
git clone https://github.com/scwatts/fastspar.git
(cd fastspar && ./configure --disable-arma-wrapper && make -j)


###
# Timed runs
###
for file in $(ls -Sr random_subsets/*); do
  basename="${file##*/}";
  noext="${basename/.tsv/}";
  filling="${noext##*random_}";
  samples="${filling%%_*}";
  otus="${filling##*_}";

  echo "current data set: ${samples} samples and ${otus} otus";

  # FastSpar (multi-thread)
  # Only run if the log file does not exist
  if ! ls logs/fastspar_threaded_"${samples}"_"${otus}".log 1>/dev/null 2>&1; then
    echo -e "\trunning fastspar threaded";
    /usr/bin/time -v taskset --cpu-list 0-15 ./fastspar/src/fastspar -c "${file}" -r output/fastspar_threaded_cor_"${samples}"_"${otus}".tsv -a output/fastspar_threaded_cov_"${samples}"_"${otus}".tsv -i 48 -x 10 -t 16 -y 1>logs/fastspar_threaded_"${samples}"_"${otus}".log 2>&1;
  fi;

  # FastSpar (single thread)
  # Only run if the log file does not exist
  if ! ls logs/fastspar_single_"${samples}"_"${otus}".log 1>/dev/null 2>&1; then
    echo -e "\trunning fastspar single";
    /usr/bin/time -v taskset --cpu-list 15 ./fastspar/src/fastspar -c "${file}" -r output/fastspar_single_cor_"${samples}"_"${otus}".tsv -a output/fastspar_single_cov_"${samples}"_"${otus}".tsv -i 48 -x 10 -t 1 -y 1>logs/fastspar_single_"${samples}"_"${otus}".log 2>&1;
  fi;

  # SparCC
  # Only run if the log file does not exist
  if ! ls logs/sparcc_"${samples}"_"${otus}".log 1>/dev/null 2>&1; then
    echo -e "\trunning sparcc";
    /usr/bin/time -v taskset --cpu-list 15 ./sparcc/SparCC.py "${file}" -c output/sparcc_cor_"${samples}"_"${otus}".tsv -v output/sparcc_cov_"${samples}"_"${otus}".tsv -i 48 -x 10 1>logs/sparcc_"${samples}"_"${otus}".log 2>&1;
  fi;
done

# Compile results
./assets/compile_profiling_results.py --profile_log_fps logs/*log --time_output_fp compiled_time.tsv --memory_output_fp compiled_memory.tsv


###
# Generate plots
###
mkdir plots
./assets/profile_plots.R
