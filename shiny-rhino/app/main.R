api_base_url <- Sys.getenv("API_BASE_URL")



box::use(
  shiny[NS, bootstrapPage, div, moduleServer, renderUI, tags],
  bslib[page_navbar, nav_panel, sidebar]
)

box::use(
  app/view/standings,
  app/view/season_input,
  app/view/match_stats,
  app/view/pnl
)

#' @export
ui <- function(id) {
  ns <- NS(id)
  page_navbar(
  title = "Bundesliga Stats",
  sidebar = sidebar(
    title = "Menu",
    season_input$ui(ns("season"))
  ),
    nav_panel(
      "Standings",
      standings$ui(ns("standings"))
    ),
    nav_panel(
      "Match Statistics",
      match_stats$ui(ns("match_stats"))
    ),
    nav_panel(
      "Betting",
      pnl$ui(ns("pnl"))
    ), 
  )
}

#' @export
server <- function(id) {
  moduleServer(id, function(input, output, session) {
    season <- season_input$server("season", api_base_url)

    
    standings$server("standings", api_base_url, season)

    matches <- match_stats$server("match_stats", api_base_url, season)

    pnl$server("pnl", matches)
  })
}
