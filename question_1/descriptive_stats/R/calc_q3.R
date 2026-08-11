#' Calculate third quartile
#'
#' Calculates the third quartile (Q3) of a numeric vector.
#' Missing values and `NaN` values are excluded from the calculation.
#'
#' @param x A numeric vector.
#'
#' @return The third quartile of `x`. Returns `NA` for an empty vector
#'   or when all values are missing.
#'
#' @examples
#' calc_q3(c(1, 2, 3, 4, 5))
#' calc_q3(c(1, 2, NA, 4))
#'
#' @export
calc_q3 <- function(x) {
  
  if (!is.numeric(x)) {
    stop(
      "`x` must be a numeric vector.\n",
      "Detected data type: ",
      typeof(x)
    )
  }
  
  if (any(is.infinite(x))) {
    stop(
      "`x` contains infinite values, which are not supported."
    )
  }
  
  if (any(is.na(x))) {
    message(
      "Missing values were excluded from the third quartile calculation."
    )
  }
  
  x <- x[!is.na(x)]
  
  if (length(x) == 0) {
    return(NA_real_)
  }
  
  as.numeric(
    stats::quantile(
      x,
      probs = 0.75,
      names = FALSE
    )
  )
}