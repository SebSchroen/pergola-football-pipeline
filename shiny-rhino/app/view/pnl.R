
# app/view/pnl_module.R

box::use(
  shiny[moduleServer, tagList, selectInput, NS, reactive, sliderInput,fluidRow, checkboxInput, 
  plotOutput, renderPlot],
  dplyr[...],
  ggplot2[...],
  tidyr[pivot_longer, unnest_wider, replace_na],
  purrr[map2]
)

box::use(
  app/logic/utils
)

ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
    sliderInput(ns("conf_threshold"), "Confidence Threshold", 0, 1, 0),
    checkboxInput(ns("home_only"), "Home Matches Only", FALSE),
    checkboxInput(ns("value_bets_only"), "Value Bets Only", FALSE)
    ),
    plotOutput(ns("pnl_plot"))
  )
}

# Module Server
server <- function(id, matches) {
  moduleServer(id, function(input, output, session) {
   

  predictions <- reactive({
    matches() |> 
    mutate(
      pre_home_rating = replace_na(pre_home_rating, 0),
      pre_away_rating = replace_na(pre_away_rating, 0),
      FTR = case_when(
        ft_home_goal > ft_away_goal ~ "H", 
        ft_home_goal < ft_away_goal ~ "A",
        TRUE ~ "D"
      )  
    ) |> 
    mutate(probs = map2(pre_home_rating, pre_away_rating, utils$calculate_match_probability)) |> 
    unnest_wider(probs) |> 
    mutate(
      # 1. Select the odds based on the prediction
      odds_taken = case_when(
        pred == "H" ~ b365_home_odds,
        pred == "D" ~ b365_draw_odds,
        pred == "A" ~ b365_a_odds
      ),
      # 2. Calculate return (1 unit stake)
      return = if_else(FTR == pred, odds_taken, 0),
      # 3. Calculate P&L
      pnl = return - 1,
      # 4. Calculate predicted probability for the chosen outcome
      pred_prob = case_when(
        pred == "H" ~ p_home_win,
        pred == "D" ~ p_draw,
        pred == "A" ~ p_away_win
      ),
      correct = if_else(FTR == pred, 1 , 0),
      # Scenario 1: Most Likely Outcome
      most_likely_outcome = case_when(
        b365_home_odds <= b365_draw_odds & b365_home_odds <= b365_a_odds ~ "H",
        b365_draw_odds < b365_home_odds & b365_draw_odds <= b365_a_odds ~ "D",
        TRUE ~ "A"
      ),
      pnl_most_likely = if_else(FTR == most_likely_outcome,
                                case_when(most_likely_outcome == "H" ~ b365_home_odds,
                                          most_likely_outcome == "D" ~ b365_draw_odds,
                                          TRUE ~ b365_a_odds) - 1, -1),
      # Scenario 2: Naive Home
      pnl_naive_home = if_else(FTR == "H", b365_home_odds - 1, -1)) |> 
      filter(
      (!input$home_only | pred == "H"),
      pred_prob >= input$conf_threshold,
      (!input$value_bets_only | (pred_prob > (1/odds_taken)))) |>
        arrange(match_date) |>
        summarise(
          pnl_model = sum(pnl),
          pnl_most_likely = sum(pnl_most_likely),
          pnl_naive_home = sum(pnl_naive_home),
          .by = match_date
        ) |>
        mutate(
          cum_pnl_model = cumsum(pnl_model),
          cum_pnl_most_likely = cumsum(pnl_most_likely),
          cum_pnl_naive_home = cumsum(pnl_naive_home)
        ) |> 

        pivot_longer(cols = starts_with("cum_pnl_"), names_to = "strategy", values_to = "cum_pnl") 

    })
     
    output$pnl_plot <- renderPlot({
      predictions() |>
        ggplot(aes(x = match_date, y = cum_pnl, color = strategy)) +
        geom_line() + geom_point() + 
        geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
        labs(x = "Date", y = "Cumulative P&L", color = "Strategy") +
        theme_minimal()
    })
      
  })
}