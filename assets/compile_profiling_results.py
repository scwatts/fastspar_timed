#!/usr/bin/env python3
import argparse
import pathlib
import re


SUFFIX_RE = re.compile(r'^.+?(\d+_\d+)\.log$')
TIME_RE = re.compile(r'\tElapsed.+?: (?:(?P<hours>\d+):)?(?P<minutes>\d+):(?P<seconds>.+)')
MEMORY_RE = re.compile(r'\tMaximum.+?: ([0-9]+)')


def get_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument('--profile_log_fps', required=True, type=pathlib.Path,
            nargs='+', help='Filepaths to profile logs')

    parser.add_argument('--time_output_fp', required=True, type=pathlib.Path,
            help='Time profile output filepath')
    parser.add_argument('--memory_output_fp', required=True, type=pathlib.Path,
            help='Memory profile output filepath')

    # Check that input files exist
    args = parser.parse_args()
    for profile_log_fp in args.profile_log_fps:
        if not profile_log_fp.exists():
            parser.error('Input file %s does not exist' % profile_log_fp)

    return args


def main():
    # Get command line arguments
    args = get_arguments()

    # Sort filepaths by suffix
    sorted_fps = dict()
    for profile_log_fp in args.profile_log_fps:
        # Get suffix
        suffix = SUFFIX_RE.match(profile_log_fp.name).group(1)

        # Add to group
        try:
            sorted_fps[suffix].append(profile_log_fp)
        except KeyError:
            sorted_fps[suffix] = [profile_log_fp]


    # Get file handle to output files
    time_fh = args.time_output_fp.open('w')
    memory_fh = args.memory_output_fp.open('w')


    # Write out header
    header = ['dataset', 'samples', 'otus']
    for fp in list(sorted_fps.values())[0]:
        prefix_end_pos = SUFFIX_RE.match(fp.name).start(1) - 1
        header.append(fp.name[:prefix_end_pos])

    print(*header, sep='\t', file=time_fh)
    print(*header, sep='\t', file=memory_fh)

    # Iterate sorted suffices and printing collected timings
    for suffix in sorted(sorted_fps, key=lambda k: int(k.split('_')[0])):
        # Get info from suffix
        samples, otus = suffix.split('_')

        # Print out dataset column
        print(suffix, samples, otus, sep='\t', end='\t', file=time_fh)
        print(suffix, samples, otus, sep='\t', end='\t', file=memory_fh)

        # Collect and print out data
        data = gather_data(sorted_fps[suffix])
        sorted_data = [data[fp] for fp in sorted(data, key=lambda k: k.name)]

        timing, memory = zip(*sorted_data)

        print(*timing, sep='\t', file=time_fh)
        print(*memory, sep='\t', file=memory_fh)

    # Close file handles
    time_fh.close()
    memory_fh.close()


def gather_data(fps):
    # Return variable
    data = dict()

    # Get timing in seconds and add to dict
    for fp in fps:
        with fp.open('r') as fh:
            lines = fh.read()

            memory_result = MEMORY_RE.search(lines)
            timing_result = TIME_RE.search(lines)

            memory = int(memory_result.group(1))
            elapsed = convert_elapsed(timing_result)

            data[fp] = (elapsed, memory)
    return data


def convert_elapsed(re_result):
    # Return variable
    time = 0

    # Multipler unit map
    conv_multi = {'hours': 3600,
                  'minutes': 60,
                  'seconds': 1}

    # Convert to seconds
    for unit, value in re_result.groupdict().items():
        if value:
            time += float(value) * conv_multi[unit]

    # Round to closest two decimal places
    return round(time, 2)


if __name__ == '__main__':
    main()
