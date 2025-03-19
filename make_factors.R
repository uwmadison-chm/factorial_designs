#!/usr/bin/env Rscript
# Copyright 2025 Board of Regents of the University of Wisconsin System

#' Generates multi-factorial randomization lists for REDCap.
#'
#' This script creates balanced randomization lists for multi-factorial designs.
#' Each factor will have a 50% probability of being 0 or 1, and this balance
#' is maintained within each block of 2^factor_count values.
#'
#' @param list_length The approximate length of the list to generate
#' @param factor_count The number of factors in the multifactorial design
#' @param file_prefix Optional: The prefix for generated filenames when writing to CSV
#'
#' @return A data frame with factors as columns and rows representing randomization allocations

# Function to generate a shuffled sequence
generate_shuffled_sequence <- function(seq_range, reps) {
  # Generate a sequence of integers from 0 to seq_range-1, repeated reps times
  # Each repetition is independently shuffled

  # Create a matrix with seq_range columns and reps rows
  sequences <- matrix(rep(0:(seq_range-1), reps), nrow = reps, byrow = TRUE)

  # Shuffle each row independently -- note that this transposes the matrix
  shuffled <- apply(sequences, 1, sample)

  # ... but that transposition is no problem because as.vector operates
  # in columnwise order
  flat_sequence <- as.vector(shuffled)

  return(flat_sequence)
}

# Function to convert integers to binary representation
bittify_sequence <- function(sequence) {
  # Convert a sequence of integers to their binary representation
  # Returns a matrix where each row is the binary representation of one integer

  # Calculate how many bits we need based on the maximum value
  max_val <- max(sequence)
  bits_needed <- ceiling(log2(max_val + 1))

  # Create a matrix to hold the binary representations
  bit_matrix <- matrix(0, nrow = length(sequence), ncol = bits_needed)

  # For each integer in the sequence
  for (i in seq_along(sequence)) {
    # Convert to binary representation
    if (sequence[i] > 0) {
      binary <- as.integer(intToBits(sequence[i]))[1:bits_needed]
      # R's intToBits gives least significant bit first, so we need to reverse
      bit_matrix[i, ] <- rev(binary)
    }
  }

  return(bit_matrix)
}

#' Generate a randomization list for a multi-factorial design
#'
#' @param list_length Approximate length of the list to generate
#' @param factor_count Number of factors in the multi-factorial design
#'
#' @return A data frame containing the randomization allocation for each factor
#'
make_factors <- function(list_length, factor_count) {
  if (factor_count < 1) {
    stop("Must generate at least one factor")
  }

  # Calculate sequence range (2^factor_count)
  seq_range <- 2^factor_count

  # Calculate repetitions needed to reach the desired list length
  reps <- ceiling(list_length / seq_range)

  # Generate the shuffled sequence
  sequence <- generate_shuffled_sequence(seq_range, reps)

  # Convert to binary representation
  bits <- bittify_sequence(sequence)

  # Create randomization numbers (1-based indexing for REDCap)
  randomization_numbers <- 1:length(sequence)

  # Create result data frame
  result <- data.frame(redcap_randomization_number = randomization_numbers)

  # Add each factor's allocation
  for (factor_num in 1:factor_count) {
    # Extract the bit for this factor (take from right to left)
    factor_col <- bits[, factor_count - factor_num + 1]

    # Add to the result data frame
    result[[paste0("factor_", factor_num)]] <- factor_col
  }

  return(result)
}

#' Write randomization lists to CSV files
#'
#' @param factors The data frame containing factor allocations
#' @param file_prefix Prefix to use for the generated filenames
#'
#' @return Invisibly returns the paths to the files that were written
#'
write_factor_csvs <- function(factors, file_prefix) {
  # Determine how many factors we have
  factor_count <- ncol(factors) - 1  # Subtract 1 for randomization number

  # Initialize vector to store filenames
  filenames <- character(factor_count)

  # For each factor, create a CSV file
  for (factor_num in 1:factor_count) {
    # Create filename
    filename <- sprintf("%s_%02d.csv", file_prefix, factor_num)
    filenames[factor_num] <- filename

    # Create a data frame for this factor
    factor_df <- data.frame(
      redcap_randomization_number = factors$redcap_randomization_number,
      redcap_randomization_group = factors[[paste0("factor_", factor_num)]]
    )

    # Write to CSV
    write.csv(factor_df, file = filename, row.names = FALSE)

    # Print status
    cat(sprintf("Writing %s\n", filename))
  }

  invisible(filenames)
}

#' Does a quick check of a factor list (really, for internal use)
#' The list is okay if:
#' * Its length is a multiple of 2^number_of_factors
#' * For each block of 2^number_of_factors rows, the mean of each factor
#'   is 0.5
#'
#' @param factor_df The generated factor list
#'
#' @return A data.frame with one row per block; each value should be 0.5
check_factors <- function(factor_df) {
  factor_count <- ncol(factor_df) - 1
  block_size <- 2 ^ factor_count
  list_length <- nrow(factor_df)
  if (list_length %% block_size != 0) {
    stop("Unexpected list length")
  }
  block_count <- list_length / block_size
  groups <- list(rep(1:block_count, each = block_size))
  aggregate(factor_df, by = groups, FUN =)
}

# Interactive R use
if (interactive()) {
  # Example usage in interactive R session
  cat("To use this module interactively in R:\n")
  cat("1. Generate a randomization list:\n")
  cat("   factors <- make_factors(list_length = 40, factor_count = 3)\n")
  cat("   # factor_list will be rounded up to a multiple of 2^factor_count\n")
  cat("   # View the data frame:\n")
  cat("   head(factors)\n\n")
  cat("2. Write the factors to CSV files:\n")
  cat("   write_factor_csvs(factors, file_prefix = 'test')\n\n")
  cat("A quick test for your list is check_factors(factor_df) -- every factor\n")
  cat("in your result should be 0.5 for every row.\n\n")
} else if (!exists("SOURCE_ONLY") || !SOURCE_ONLY) {
  # Command line usage
  args <- commandArgs(trailingOnly = TRUE)

  if (length(args) < 3) {
    cat("Usage: Rscript make_factors.R list_length factor_count file_prefix\n")
    quit(status = 1)
  }

  list_length <- as.integer(args[1])
  factor_count <- as.integer(args[2])
  file_prefix <- args[3]

  if (factor_count < 1) {
    cat("Must generate at least one factor\n")
    quit(status = 1)
  }

  cat(sprintf("Generating randomization with %d factors, approx %d entries\n",
              factor_count, list_length))

  # Generate the factors
  factors <- make_factors(list_length, factor_count)

  # Write to CSV files
  write_factor_csvs(factors, file_prefix)
}
