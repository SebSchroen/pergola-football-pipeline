



  
box::use(
  shiny[h3, moduleServer, observe, selectInput, NS, reactive, updateSelectInput],
  httr2[...],
  dplyr[pull, distinct, arrange]
)

#' @export
ui <- function(id) {
  ns <- NS(id)

  selectInput(ns("season"), "Select Season", choices = c('2024-2025', '2025-2026'))
}

#' @export
server <- function(id, api_base_url) {
  moduleServer(id, 
    function(input, output, session) {
    
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
    
      
    return(reactive({ input$season }))
    

    })
}