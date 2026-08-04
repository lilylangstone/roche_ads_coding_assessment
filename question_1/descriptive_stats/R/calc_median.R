#' Calculate the median
#'
#' Calculates the median of a numeric vector. Missing values and `NaN`
#' values are excluded from the calculation.
#'
#' @param x A numeric vector.
#' @return A single numeric value representing the median of the input
#'   vector. Returns `NA_real_` if the input is empty or all values are
#'   missing after removing `NA`s and `NaN`s.
#' @examples
#' calc_median(c(1, 2, 3))
#' calc_median(c(1, 2, NA, 4))
#' @export
calc_median <- function(x) {
  
  if (length(x) == 0) { return(NA_real_) }
  
  if (!(is.numeric(x) || (is.logical(x) && all(is.na(x))))) {
    stop(
      paste(
        "`x` must be a numeric vector.",
        "\nDetected data type:",
        typeof(x)
      )
    )
  }
  
  if (any(is.infinite(x))) {
    stop("`x` contains infinite values, which are not supported.")
  }
  
  if (any(is.na(x) | is.nan(x))) {
    message("Missing values were excluded from the median.")
    x <- x[!(is.na(x) | is.nan(x))]
  }
  
  if (length(x) == 0) { return(NA_real_) }
  
  x <- sort(x)
  n <- length(x)
  
  if (n %% 2 == 1) {
    return(x[(n + 1) / 2])
  }
  
  return((x[n / 2] + x[(n / 2) + 1]) / 2)
}