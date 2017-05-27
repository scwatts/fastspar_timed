#!/usr/bin/env python3
import argparse
import pathlib
import random


def get_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument('-c', '--count_table', required=True, type=pathlib.Path,
            help='Filepath to input OTU table')
    parser.add_argument('-a', '--sample_number', required=True, type=int,
            help='Number of samples to randomly select')
    parser.add_argument('-t', '--otu_number', required=True, type=int,
            help='Number of OTUs to randomly select')
    parser.add_argument('-s', '--seed', default=0, type=int,
            help='Seed for pseudo-random number generator')

    # Check that the input file exists
    args = parser.parse_args()
    if not args.count_table.exists():
        parser.error('Input file %s does not exist' % args.count_table)

    return args


def main():
    # Get command line arguments
    args = get_arguments()


    # Set PRNG seed
    random.seed(args.seed)


    # Determine number of OTUs in the file
    with args.count_table.open('r') as f:
        for otu_count, line in enumerate(f, 0):
            pass

    # Make a random choice for OTUs
    otu_indices = set(random.sample(range(otu_count), args.otu_number))


    # Read in header, randomly select indices and then process file data
    with args.count_table.open('r') as f:
        # Get sample count and then make random selection
        header = f.readline().rstrip().split('\t')
        sample_count = len(header) - 1

        # Incrementing sample_count to account for row names in data; also
        # adding index 0 to capture the row name when we output results
        sample_indices = set(random.sample(range(1, sample_count+1), args.sample_number))
        sample_indices.add(0)


        # Print header and then process file
        header_selected = [el for j, el in enumerate(header) if j in sample_indices]
        print(*header_selected, sep='\t')

        for otu_index, line in enumerate(f):
            # Skip if this OTU was not selected
            if not otu_index in otu_indices:
                continue

            # Select samples where j is the sample index
            col_gen = (col for col in line.rstrip().split('\t'))
            data = [el for j, el in enumerate(col_gen) if j in sample_indices]

            # Print out data
            print(*data, sep='\t')

    return


if __name__ == '__main__':
    main()
