#' Calculate the arithmetic mean
#'
#' Calculates the arithmetic mean of a numeric vector. Missing values
#' are excluded from the calculation.
#'
#' @param x A numeric vector.
#' @return A single numeric value representing the arithmetic mean of
#'   the input vector. Returns `NA_real_` if the input vector is empty
#'   or if all values are missing after removing `NA`s.
#' @examples
#' calc_mean(c(1, 2, 3))
#' calc_mean(c(1, 2, NA, 4))
#' @export
calc_mean <- function(x) {
  
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
    message("Missing values were excluded from the calculation.")
    x <- x[!(is.na(x) | is.nan(x))]
  }
  
  if (length(x) == 0) { return(NA_real_) }
  
  return(sum(x) / length(x))
}