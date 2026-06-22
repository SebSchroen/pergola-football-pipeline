
box::use(
  stats[pnorm],
  tibble[tibble]
)

#' @export
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