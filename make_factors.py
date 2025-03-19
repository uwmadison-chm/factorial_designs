#!/usr/bin/env python
# Copyright 2025 Board of Regents of the University of Wisconsin System

"""
Generates multi-factorial randomization lists for REDCap.

Takes three parameters:
* list_length (the approximate length of the list you want to generate
* factor_count (the number of factors in your multifactorial design)
* file_prefix (the start of the generated filenames)

The actual list length will be a multiple of 2^factor_count, we round up.

The script will generate factor_count output files. Each output has two columns:
redcap_randomization_number (counts up from 1 to the actual list length)
redcap_randomization_group  (1 or 0, depending on whether this factor is true
                             for this record)

"""

import sys

import numpy as np

import logging
logging.basicConfig(format="%(message)s")
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)


def generate_shuffled_sequence(seq_range, reps):
    """
    Generate a length * reps length sequence of numbers ranging from 0 to
    length-1, with each sequence shuffled randomly.
    """
    rng = np.random.default_rng()
    
    sequences = np.tile(np.arange(seq_range, dtype=">i4"), (reps, 1))
    shuffled = rng.permuted(sequences, axis=1)
    flat = shuffled.flatten()
    return flat


def bittify_sequence(seq):
    """
    Turns a sequence of uint8 numbers into their bitwise representation
    Output will be of shape (seq, 8)
    """
    return np.unpackbits(seq.view(np.uint8)).reshape(len(seq), -1)


def make_factor_array(list_length, factor_count):
    seq_range = 2**factor_count
    logger.debug(f"sequence range: {seq_range}")
    reps = int(np.ceil(list_length / seq_range))
    logger.debug(f"reps: {reps}")
    sequence = generate_shuffled_sequence(seq_range, reps)
    actual_list_length = len(sequence)
    logger.debug(f"actual list length: {actual_list_length}")
    bits = bittify_sequence(sequence)
    # Bits will be filled in from the right side of the array
    return bits[:, -factor_count:]


def main(list_length, factor_count, file_prefix):
    factor_bits = make_factor_array(list_length, factor_count)
    logger.info(factor_bits)
    
    final_list_length = factor_bits.shape[0]
    randomization_numbers = np.arange(1, final_list_length + 1)

    for factor_num in range(1, factor_count + 1):
        slice_index = factor_num - 1
        fname = f"{file_prefix}_{factor_num:02d}.csv"
        factor_assignments = factor_bits[:, slice_index]
        logger.debug(factor_assignments)
        with open(fname, "w") as out:
            logger.info(f"Writing {fname}")
            out.write("redcap_randomization_number,redcap_randomization_group\n")
            for linenum in range(final_list_length):
                out.write(f"{randomization_numbers[linenum]},{factor_assignments[linenum]}\n")


if __name__ == "__main__":
    if len(sys.argv) < 4:
        logger.error("Usage: make_factors.py <list_length> <factor_count> <csv_prefix>")
        sys.exit(1)
    list_length, factor_count = [int(s) for s in sys.argv[1:3]]
    file_prefix = sys.argv[3]
    if factor_count < 1 or factor_count > 16:
        logger.error("Must generate between 1 and 16 factors")
        sys.exit(1)
    main(list_length, factor_count, file_prefix)
