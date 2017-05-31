#!/usr/bin/env python3
import argparse
import pathlib
import re


SUFFIX_RE = re.compile(r'^.+?(\d+_\d+)\.log$')
TIME_RE = re.compile(r'^.+: (?:(?P<hours>\d+):)?(?P<minutes>\d+):(?P<seconds>.+)$')


def get_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument('--timing_log_fps', required=True, type=pathlib.Path,
            nargs='+', help='Filepaths to timing logs')

    # Check that input files exist
    args = parser.parse_args()
    for timing_log_fp in args.timing_log_fps:
        if not timing_log_fp.exists():
            parser.error('Input file %s does not exist' % timing_log_fp)

    return args


def main():
    # Get command line arguments
    args = get_arguments()

    # Sort filepaths by suffix
    sorted_fps = dict()
    for timing_log_fp in args.timing_log_fps:
        # Get suffix
        suffix = SUFFIX_RE.match(timing_log_fp.name).group(1)

        # Add to group
        try:
            sorted_fps[suffix].append(timing_log_fp)
        except KeyError:
            sorted_fps[suffix] = [timing_log_fp]


    # Print out header
    header = ['dataset']
    for fp in list(sorted_fps.values())[0]:
        prefix_end_pos = SUFFIX_RE.match(fp.name).start(1) - 1
        header.append(fp.name[:prefix_end_pos])
    print(*header, sep='\t')


    # Iterate sorted suffices and printing collected timings
    for suffix in sorted(sorted_fps, key=lambda k: int(k.split('_')[0])):
        # Print out dataset column
        print(suffix, end='\t')

        # Collect and print out timings
        timings = gather_timings(sorted_fps[suffix])

        sorted_timings = [timings[fp] for fp in sorted(timings, key=lambda k: k.name)]
        print(*sorted_timings, sep='\t')


def gather_timings(fps):
    # Return variable
    timings = dict()

    # Get timing in seconds and add to dict
    for fp in fps:
        with fp.open('r') as fh:
            for line in fh:
                if 'Elapsed' in line:
                    elapsed = convert_elapsed(line)
                    timings[fp] = elapsed
                    break

    return timings


def convert_elapsed(elapsed_line_string):
    # Return variable
    time = 0

    # Multipler unit map
    conv_multi = {'hours': 3600,
                  'minutes': 60,
                  'seconds': 1}

    # Get the time tokens
    results = TIME_RE.match(elapsed_line_string).groupdict()

    # Convert to seconds
    for unit, value in results.items():
        if value:
            time += float(value) * conv_multi[unit]

    # Round to closest two decimal places
    return round(time, 2)


if __name__ == '__main__':
    main()
