#' Calculate the mode
#'
#' Calculates the most frequently occurring value or values in a numeric
#' vector. Missing values and `NaN` values are excluded from the calculation.
#'
#' @param x A numeric vector.
#' @return A numeric vector containing the most frequently occurring value
#'   or values. Returns `NA_real_` if the input is empty, all values are
#'   missing, or no value occurs more frequently than another.
#' @examples
#' calc_mode(c(1, 2, 2, 3))
#' calc_mode(c(1, 1, 2, 2, 3))
#' calc_mode(c(1, 2, NA, 2))
#' @export
calc_mode <- function(x) {
  
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
    message("Missing values were excluded from the mode.")
    x <- x[!(is.na(x) | is.nan(x))]
  }
  
  if (length(x) == 0) { return(NA_real_) }
  
  if (length(x) == 1) { return(x) }
  
  frequencies <- table(x)
  highest_frequency <- max(frequencies)
  
  if (highest_frequency == 1) { return(NA_real_) }
  
  modes <- as.numeric(names(frequencies)[frequencies == highest_frequency])
  
  return(modes)
}