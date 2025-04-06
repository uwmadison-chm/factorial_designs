# Factorial design scripts
R and python scripts for generating factorial study randomization designs

If you're running a research study where you want to randomize several (or many!) boolean conditions, this code may help you do that! It's geared towards generating randomization lists for use in REDCap, but the randomization code is the same for any study design technology. If you'd like a reference for this, see [this paper by Collins et al](https://psycnet.apa.org/record/2009-12975-002).

Let's say you're running a study where you want to simultaneously test the effects of:

1. An antidepressant
2. Exercise
3. Talk therapy

Then the number of potential combinations of conditions is 2^3 = 8. Both the R and python functions will generate 3 independent lists of a specified length, where in every group of 8 rows, half the conditions will be 1 and half will be 0.

## R code

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

## Python code

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

## REDCap setup

Note: This requires **REDCap Version 14.7.0** or later -- earlier versions do not support multiple randomization models or logic-based randomization. Also: _I am not a biostatistician_ and can not advise you on how to design your study.

Somewhere in your study, create fields for your randomization. Call them whatever you want. Make them multiple choice fields or yes/no fields, the available values should be 0 and 1. _These fields do not need to be in the flow of surveys._ You can have your randomization fields in a staff-only form and the randomization models will fill the values when they trigger.

Add a randomization model for each of your randomization fields. Assign one to each of your randomization fields, and upload the corresponding CSV file with your randomization data.

Optional but probably what you want: Set Automatic Triggering to the same thing for each each of your randomization models. Triggering on something like completing consent, or completing baseline surveys, might be what you want.

There is a [demo REDCap project](https://github.com/uwmadison-chm/factorial_designs/blob/main/FactorialDesignREDCapDemo.xml) included in this repository to get you started.
