# descriptiveStats

A lightweight R package for calculating common descriptive statistics on
numeric vectors.

## Features

The package provides the following functions:

- `calc_mean()` – Calculate the arithmetic mean.
- `calc_median()` – Calculate the median.
- `calc_mode()` – Calculate the mode, including tied modes and no-mode cases.
- `calc_q1()` – Calculate the first quartile (Q1).
- `calc_q3()` – Calculate the third quartile (Q3).
- `calc_iqr()` – Calculate the interquartile range (IQR).

## Installation

```r
devtools::install("question_1/descriptiveStats")
```

## Example

```r
library(descriptiveStats)

data <- c(1, 2, 2, 3, 4, 5, 5, 5, 6, 10)

calc_mean(data)
calc_median(data)
calc_mode(data)
calc_q1(data)
calc_q3(data)
calc_iqr(data)
```

## Input Requirements

All functions expect a numeric vector as input.

The package:

- Excludes `NA` and `NaN` values from calculations.
- Returns informative error messages for invalid input types.
- Returns `NA_real_` for empty vectors or when no valid observations remain.
- Rejects infinite (`Inf` and `-Inf`) values.

## Package Structure

```
descriptiveStats/
├── DESCRIPTION
├── NAMESPACE
├── R/
├── man/
└── README.md
```