library(httr2)
library(shiny)
library(bslib)
library(dplyr)
library(tidyr)
library(ggplot2)
reactlog::reactlog_enable()
# Define the base URL of your running Plumber API
api_base_url <- Sys.getenv("API_BASE_URL")

ui <- page_navbar(
  title = "Bundesliga Stats",
  sidebar = sidebar(
  title = "Menu",
  selectInput("season", label = "Season", choices = NULL),
  selectInput("round", label = "Match Day", choices = 34:1),
  ),
  navset_card_tab(
    title = "Statistics",
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

    )
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

}


shinyApp(ui, server)