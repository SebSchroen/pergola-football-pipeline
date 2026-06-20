library(httr2)
library(shiny)
library(bslib)
library(dplyr)
library(tidyr)
library(ggplot2)
library(purrr)
# Define the base URL of your running Plumber API
api_base_url <- Sys.getenv("API_BASE_URL")

#source("utils/compute_probabilities.R")

 

ui <- page_navbar(
  title = "Bundesliga Stats",
  sidebar = sidebar(
    title = "Menu",
    selectInput("season", "Select Season", choices = c('2024-2025', '2025-2026')),
  ),
    nav_panel(
      "Standings",
      standingsUI("standings")
    ),
    nav_panel(
      "Statistics",
      match_statsUI("match_stats")
    ),
    nav_panel(
      "xpts vs. pts",
      card_title("Expected vs. Actual Points"),
      plotOutput("xpts_vs_pts")
    ),
    nav_panel(
      "Betting",
      card_title("Cumulative P&L"),
      pnlUI("pnl_plot")
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


  standings <- standingsServer("standings",api_base_url =  api_base_url, season = reactive({ input$season }) )
  
  matches <- match_statsServer("match_stats",api_base_url =  api_base_url, season = reactive({ input$season }))


  output$xpts_vs_pts <- renderPlot({
   
    ggplot(data = standings(), aes(x=xpts, y = points, label = team)) +
      geom_abline(slope = 1, intercept = 0) +
      geom_label() +
      labs(x = "Expected Points", y = "Points") +
      ggtitle("Points vs. Expected Points") +
      theme_classic()
  })

  pnlServer("pnl_plot", matches = matches )
  
}


shinyApp(ui, server)