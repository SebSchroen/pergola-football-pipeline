# app/view/standings.R

box::use(
  shiny[moduleServer, tagList, tableOutput, NS, renderTable, req, reactive],
  httr2[...],
  dplyr[...]
)


#' @export
ui <- function(id) {
  ns <- NS(id)
  tagList(
    tableOutput(ns("table"))
  )
}

#' @export
#' @param api_base_url base URL of the Bundesliga Plumber API
#' @param season Reactive season parameter passsed from the global SelectInput
server <- function(id, api_base_url, season) {
  moduleServer(id, function(input, output, session) {
   

    standings_data <- reactive({
      req(season) # Wait for the parent to pass a season

      request(api_base_url) |>
        req_url_path_append("table") |>
        req_url_query(season = season()) |> # Use the passed reactive here
        req_perform() |>
        resp_body_raw() |>
        unserialize() |>
        select(-c(season)) |>
        arrange(rank)
    })
    
    output$table <- renderTable({
      standings_data()
    })
    # Render the table using the passed reactive data
    return(standings_data) 
    
  })
}
