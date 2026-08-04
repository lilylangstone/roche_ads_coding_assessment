# descriptiveStats package test cases
library(descriptiveStats)

# Example data supplied in the assessment
data <- c(1, 2, 2, 3, 4, 5, 5, 5, 6, 10)

# Standard results
calc_mean(data)       # Expected: 4.3 (incorrect in documentation)
calc_median(data)     # Expected: 4.5
calc_mode(data)       # Expected: 5
calc_q1(data)         # Expected: 2.5
calc_q3(data)         # Expected: 5.5
calc_iqr(data)        # Expected: 3

# Empty vectors
calc_mean(numeric(0))     # Expected: NA
calc_median(numeric(0))   # Expected: NA
calc_mode(numeric(0))     # Expected: NA
calc_q1(numeric(0))       # Expected: NA
calc_q3(numeric(0))       # Expected: NA
calc_iqr(numeric(0))      # Expected: NA

# Missing values
calc_mean(c(1, 2, NA, 4))
calc_median(c(1, 2, NA, 4))
calc_mode(c(1, 2, NA, 2))
calc_q1(c(1, 2, NA, 4))
calc_q3(c(1, 2, NA, 4))
calc_iqr(c(1, 2, NA, 4))

# NaN values
calc_mean(c(1, 2, NaN, 4))
calc_median(c(1, 2, NaN, 4))
calc_mode(c(1, 2, NaN, 2))
calc_q1(c(1, 2, NaN, 4))
calc_q3(c(1, 2, NaN, 4))
calc_iqr(c(1, 2, NaN, 4))

# Single values
calc_mean(42)         # Expected: 42
calc_median(42)       # Expected: 42
calc_mode(42)         # Expected: 42
calc_q1(42)           # Expected: 42
calc_q3(42)           # Expected: 42
calc_iqr(42)          # Expected: 0

# Mode edge cases
calc_mode(c(1, 1, 2, 2, 3))   # Expected: 1 and 2
calc_mode(c(1, 2, 3, 4))      # Expected: NA

# Invalid inputs — expected errors
calc_mean(c("apple", "banana"))
calc_median(list(1, 2, 3))
calc_mode(c(TRUE, FALSE))
calc_q1(c(1, 2, Inf))
calc_q3(c(1, 2, -Inf))
calc_iqr(c("apple", "banana"))

# Large vector
large_data <- seq_len(1000000)
calc_iqr(large_data)           # Expected: 500000