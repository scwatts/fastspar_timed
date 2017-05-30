#!/bin/bash


###
# Prepare data
###
# Decompress OTU table
gzip -d assets/otu_table_cluster_99_collapsed.tsv.gz

# Generate random subsamples of CAS filtered and reduced OTU table
mkdir random_subsets
parallel -N1 --link './assets/generate_random_subsets.py -c assets/otu_table_cluster_99_collapsed.tsv -a {1} -t {2} > random_subsets/otu_table_cluster_99_filtered_reduced_random_{1}_{2}.tsv' ::: $(seq 40 40 4000) ::: $(seq 60 60 6000)

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
for file in random_subsets/*; do
  basename="${file##*/}";
  noext="${basename/.tsv/}";
  filling="${noext##*random_}";
  samples="${filling%%_*}";
  otus="${filling##*_}";

  # FastSpar (multi-thread)
  # Only run if the log file does not exist
  if ! ls logs/fastspar_threaded_"${samples}"_"${otus}".log 1>/dev/null 2>&1; then
    /usr/bin/time -v ./fastspar/src/fastspar -c "${file}" -r output/fastspar_threaded_cor_"${samples}"_"${outs}".tsv -a output/fastspar_threaded_cov_"${samples}"_"${outs}".tsv -i 48 -x 10 -t 24 1>logs/fastspar_threaded_"${samples}"_"${otus}".log 2>&1;
  fi;

  # FastSpar (single thread)
  # Only run if the log file does not exist
  if ! ls logs/fastspar_single_"${samples}"_"${otus}".log 1>/dev/null 2>&1; then
    /usr/bin/time -v ./fastspar/src/fastspar -c "${file}" -r output/fastspar_single_cor_"${samples}"_"${outs}".tsv -a output/fastspar_single_cov_"${samples}"_"${outs}".tsv -i 48 -x 10 -t 1 1>logs/fastspar_single_"${samples}"_"${otus}".log 2>&1;
  fi;

  # SparCC
  # Only run if the log file does not exist
  if ! ls logs/sparcc_"${samples}"_"${otus}".log 1>/dev/null 2>&1; then
    /usr/bin/time -v ./sparcc/SparCC.py "${file}" -c output/sparcc_cor_"${samples}"_"${otus}".tsv -v output/sparcc_cov_"${samples}"_"${otus}".tsv -i 48 -x 10 1>logs/sparcc_"${samples}"_"${otus}".log 2>&1;
  fi;
done
