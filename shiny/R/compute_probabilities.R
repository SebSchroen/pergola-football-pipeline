#' Calculate Match Probabilities Based on Team Ratings
#'
#' This function computes the probabilities of home win, draw, and away win
#' in a football (soccer) match using team ratings and a normal distribution model.
#' The probabilities are based on the difference between home and away team ratings,
#' with an optional sigma parameter to control the uncertainty in predictions.
#'
#' @param home_rating Numeric value representing the strength rating of the home team
#' @param away_rating Numeric value representing the strength rating of the away team
#' @param sigma Numeric value (default = 1.0) representing the standard deviation
#'              of the normal distribution used to model the goal difference.
#'              Higher values indicate more uncertainty in predictions.
#'
#' @return A tibble containing:
#' \itemize{
#'   \item p_home_win: Probability of home team winning
#'   \item p_draw: Probability of the match ending in a draw
#'   \item p_away_win: Probability of away team winning
#'   \item pred: Most likely outcome ("H" for home win, "D" for draw, "A" for away win)
#' }
#'
#' @examples
#' # Example with evenly matched teams
#' calculate_match_probability(1500, 1500)
#'
#' # Example with home team favored
#' calculate_match_probability(1600, 1400)
#'
#' # Example with custom uncertainty
#' calculate_match_probability(1550, 1500, sigma = 1.5)
#'
#' @note
#' The function assumes a draw margin of 0.5 goals. This means any goal difference
#' between -0.5 and +0.5 is considered a draw. The probabilities are calculated
#' using the cumulative distribution function (pnorm) of the normal distribution.
calculate_match_probability <- function(home_rating, away_rating, sigma = 1.0) {
  # Calculate the expected goal difference (home - away)
  expected_diff <- home_rating - away_rating

  # Define the draw margin - any result within ±0.5 goals is considered a draw
  draw_margin <- 0.5

  # Calculate probability of draw:
  # P(-0.5 < goal_diff < 0.5) = P(goal_diff < 0.5) - P(goal_diff < -0.5)
  prob_draw <- pnorm(draw_margin, mean = expected_diff, sd = sigma) -
    pnorm(-draw_margin, mean = expected_diff, sd = sigma)

  # Calculate probability of home win:
  # P(goal_diff > 0.5) = 1 - P(goal_diff < 0.5)
  prob_home_win <- 1 - pnorm(draw_margin, mean = expected_diff, sd = sigma)

  # Calculate probability of away win:
  # P(goal_diff < -0.5)
  prob_away_win <- pnorm(-draw_margin, mean = expected_diff, sd = sigma)

  # Combine probabilities into a vector
  outcomes <- c(prob_home_win, prob_draw, prob_away_win)

  # Determine most likely outcome
  most_likely <- c("H", "D", "A")[which.max(outcomes)]

  # Return results as a tibble
  return(tibble(
    p_home_win = prob_home_win,
    p_draw = prob_draw,
    p_away_win = prob_away_win,
    pred = most_likely
  ))
}