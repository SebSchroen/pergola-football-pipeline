library(httr2)
library(shiny)
library(bslib)
library(dplyr)
library(tidyr)
library(ggplot2)
library(purrr)
# Define the base URL of your running Plumber API
api_base_url <- Sys.getenv("API_BASE_URL")

source("utils/compute_probabilities.R")


  matches <-  request(api_base_url) |> 
  req_url_path_append("matches", '2024-2025') |> 
  req_url_query() |> 
  req_perform() |> 
  resp_body_raw() |> 
  unserialize()

  

ui <- page_navbar(
  title = "Bundesliga Stats",
  sidebar = sidebar(
    title = "Menu",
    selectInput("season", label = "Season", choices = '2025-2026'),
    selectInput("round", label = "Match Day", choices = 34:1),
    hr(),
    checkboxInput("home_only", "Home Matches Only", FALSE),
    sliderInput("conf_threshold", "Confidence Threshold", 0, 1, 0),
    checkboxInput("value_bets_only", "Value Bets Only", FALSE)
  ),
    nav_panel(
      "Standings",
      card_title("Current Standings"),
      tableOutput("table")
    ),
    nav_panel(
      "Statistics",
      card_title("Match Statistics"),
      tableOutput("match_stats")
    ),
    nav_panel(
      "xpts vs. pts",
      card_title("Expected vs. Actual Points"),
      plotOutput("xpts_vs_pts")
    ),
    nav_panel(
      "Betting",
      card_title("Cumulative P&L"),
      plotOutput("pnl_plot")
    )

)


server <- function(input, output, session) {
  
 observe({
    seasons <- request(api_base_url) |> 
    req_url_path_append("table") |> 
    req_url_query() |> 
    req_perform() |> 
    resp_body_raw() |> 
    unserialize() |> 
    distinct(season) |> 
    arrange(desc(season)) |> 
    pull() 
    
    updateSelectInput(session, "season", choices = seasons)
  })
  

  table <- reactive({
    request(api_base_url) |> 
    req_url_path_append("table") |> 
    req_url_query(season = input$season) |> 
    req_perform() |> 
    resp_body_raw() |> 
    unserialize() |> 
    select(-c(season)) |> 
    arrange(rank)

  })
  output$table <- renderTable({

    table()

  })

  output$match_stats <- renderTable({
    matches <-  request(api_base_url) |> 
    req_url_path_append("matches", input$season) |> 
    req_url_query() |> 
    req_perform() |> 
    resp_body_raw() |> 
    unserialize()

    matchday <- matches |>   
    select(match_date, team_home, team_away) |> 
    pivot_longer(cols = c(team_home, team_away), names_to = "home_away", values_to="team") |> 
    mutate(match_day = 1:n(), .by = c(team)) |> 
    distinct(match_date, match_day, team) 

    left_join(matches, matchday, by = c("team_home" = "team", "match_date")) |> 
    rename(home_team_match_day = match_day) |> 
    left_join(matchday, by = c("team_away" = "team", "match_date")) |> 
    rename(away_team_match_day = match_day) |> 
    mutate(round = pmax(home_team_match_day, away_team_match_day)) |> 
    select(round, match_date, team_home, team_away, ft_home_goal, ft_away_goal, xg_home, xg_away) |> 
      filter(round==input$round)
  })
  output$xpts_vs_pts <- renderPlot({
   
    ggplot(data = table(), aes(x=xpts, y = points, label = team)) +
      geom_abline(slope = 1, intercept = 0) +
      geom_label() +
      labs(x = "Expected Points", y = "Points") +
      ggtitle("Points vs. Expected Points") +
      theme_classic()
  })

  output$pnl_plot <- renderPlot({
    

  matches <-  request(api_base_url) |> 
  req_url_path_append("matches", input$season) |> 
  req_url_query() |> 
  req_perform() |> 
  resp_body_raw() |> 
  unserialize()

predictions <- matches |> 
  mutate(
    pre_home_rating = replace_na(pre_home_rating, 0),
    pre_away_rating = replace_na(pre_away_rating, 0),
    FTR = case_when(
      ft_home_goal > ft_away_goal ~ "H", 
      ft_home_goal < ft_away_goal ~ "A",
      TRUE ~ "D"
    )  
  ) |> 
  mutate(probs = map2(pre_home_rating, pre_away_rating, calculate_match_probability)) |> 
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
    pnl_naive_home = if_else(FTR == "H", b365_home_odds - 1, -1)
  )
    
    predictions |>
      filter(
        (!input$home_only | pred == "H"),
        pred_prob >= input$conf_threshold,
        (!input$value_bets_only | (pred_prob > (1/odds_taken)))
      ) |>
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
      pivot_longer(cols = starts_with("cum_pnl_"), names_to = "strategy", values_to = "cum_pnl") |>
      ggplot(aes(x = match_date, y = cum_pnl, color = strategy)) +
      geom_line() +
      geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
      labs(x = "Date", y = "Cumulative P&L", color = "Strategy") +
      theme_minimal()
  })

}


shinyApp(ui, server)