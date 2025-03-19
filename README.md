# Multifactorial design scripts
R and python scripts for generating multifactorial study randomization designs

If you're running a research study where you want to randomize several (or many!) boolean conditions, this code may help you do that! It's geared towards generating randomization lists for use in REDCap, but the randomization code is the same for any study design technology.

Let's say you're running a study where you want to simultaneously test the effects of:

1. An antidepressant
2. Exercise
3. Talk therapy

Then the number of potential combinations of conditions is 2^3 = 8. Both the R and python functions will generate 3 independent lists of a specified length, where in every group of 8 rows, half the conditions will be 1 and half will be 0.

Run the R code like:

```
> source("make_factors.R")
To use this module interactively in R:
1. Generate a randomization list:
   factors <- make_factors(list_length = 40, factor_count = 3)
   # factor_list will be rounded up to a multiple of 2^factor_count
   # View the data frame:
   head(factors)

2. Write the factors to CSV files:
   write_factor_csvs(factors, file_prefix = 'test')

A quick test for your list is check_factors(factor_df) -- every factor
in your result should be 0.5 for every row.

> factor_df <- make_factors(10, 3)
> factor_df
   redcap_randomization_number factor_1 factor_2 factor_3
1                            1        0        1        0
2                            2        1        1        1
3                            3        1        0        0
4                            4        0        1        1
5                            5        1        1        0
6                            6        0        0        0
7                            7        1        0        1
8                            8        0        0        1
9                            9        1        0        0
10                          10        1        0        1
11                          11        0        0        1
12                          12        0        0        0
13                          13        1        1        0
14                          14        1        1        1
15                          15        0        1        0
16                          16        0        1        1

> write_factor_csvs(factor_df, "test2")
Writing test2_01.csv
Writing test2_02.csv
Writing test2_03.csv
```


The python code is similar:

```
make_blocks.py <list_length> <number_of_factors> <csv_prefix>
```

It'll generate `<number_of_factors>` CSV files with the proper columns for REDCap lists.

You can also use the python function directly:

```
>>> import make_factors

>>> factor_ar = make_factors.make_factor_array(10, 3)
>>> factor_ar
[[0 1 0]
 [1 0 0]
 [0 0 1]
 [1 0 1]
 [0 1 1]
 [1 1 1]
 [1 1 0]
 [0 0 0]
 [1 0 1]
 [1 0 0]
 [0 0 1]
 [1 1 0]
 [0 1 1]
 [0 0 0]
 [1 1 1]
 [0 1 0]]
```

