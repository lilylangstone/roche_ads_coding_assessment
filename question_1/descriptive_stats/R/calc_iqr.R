#' Calculate the interquartile range
#'
#' Calculates the interquartile range (IQR) of a numeric vector as
#' the difference between the third quartile and first quartile.
#' Missing values and `NaN` values are excluded from the calculation.
#'
#' @param x A numeric vector.
#' @return A single numeric value representing the interquartile range.
#'   Returns `NA_real_` if the input is empty or all values are missing
#'   after removing `NA`s and `NaN`s.
#' @examples
#' calc_iqr(c(1, 2, 2, 3, 4, 5, 5, 5, 6, 10))
#' calc_iqr(c(1, 2, NA, 4, 5))
#' @export
calc_iqr <- function(x) {
  
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
    message("Missing values were excluded from the interquartile range calculation.")
    x <- x[!(is.na(x) | is.nan(x))]
  }
  
  if (length(x) == 0) { return(NA_real_) }
  
  return(calc_q3(x) - calc_q1(x))
}