
# R/app/view/match_stats.R

box::use(
  shiny[moduleServer, tagList, tableOutput, NS, renderTable, req, selectInput, reactive],
  httr2[...],
  dplyr[...],
  tidyr[pivot_longer]
)

ui <- function(id) {
  ns <- NS(id)
  tagList(
    
    selectInput(ns("round"), label = "Match Day", choices = 34:1),
    tableOutput(ns("match_stats"))
  )
}

# Module Server
server <- function(id, api_base_url, season) {
  moduleServer(id, function(input, output, session) {

    matches <-  reactive({
    request(api_base_url) |> 
    req_url_path_append("matches", season()) |> 
    req_url_query() |> 
    req_perform() |> 
    resp_body_raw() |> 
    unserialize()
    })

    match_stats <- reactive({
    
    matchday <- matches() |>   
    select(match_date, team_home, team_away) |> 
    pivot_longer(cols = c(team_home, team_away), names_to = "home_away", values_to="team") |> 
    mutate(match_day = 1:n(), .by = c(team)) |> 
    distinct(match_date, match_day, team) 
    
    left_join(matches(), matchday, by = c("team_home" = "team", "match_date")) |> 
    rename(home_team_match_day = match_day) |> 
    left_join(matchday, by = c("team_away" = "team", "match_date")) |> 
    rename(away_team_match_day = match_day) |> 
    mutate(round = pmax(home_team_match_day, away_team_match_day)) |> 
    select(round, match_date, team_home, team_away, ft_home_goal, ft_away_goal, xg_home, xg_away) |> 
    filter(round==input$round)
    })

    output$match_stats <- renderTable({
      match_stats()
    })

    # Return the matches raw data for further use
    return(matches) 
    
  })
}