#' Calculate the third quartile
#'
#' Calculates the third quartile (Q3) of a numeric vector using the
#' 3n/4 + 1 position method with linear interpolation.
#' Missing values and `NaN` values are excluded from the calculation.
#'
#' @param x A numeric vector.
#' @return A single numeric value representing the third quartile.
#'   Returns `NA_real_` if the input is empty or all values are missing
#'   after removing `NA`s and `NaN`s.
#' @examples
#' calc_q3(c(1, 2, 2, 3, 4, 5, 5, 5, 6, 10))
#' calc_q3(c(1, 2, NA, 4, 5))
#' @export

calc_q3 <- function(x) {
  
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
    message("Missing values were excluded from the third quartile calculation.")
    x <- x[!(is.na(x) | is.nan(x))]
  }
  
  if (length(x) == 0) { return(NA_real_) }
  
  if (length(x) == 1) { return(x) }
  
  x <- sort(x)
  n <- length(x)
  
  position <- (3 * n) / 4 + 1
  
  lower <- floor(position)
  upper <- ceiling(position)
  
  if (lower == upper) {
    return(x[lower])
  }
  
  fraction <- position - lower
  
  return(x[lower] + fraction * (x[upper] - x[lower]))
}