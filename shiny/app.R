library(httr2)

# Define the base URL of your running Plumber API
api_base_url <- "http://api-pergola-football-pipeline-dev.apps.pergola.cloud/" # Or your production URL

# 1. Querying /matches/<season> (Path Parameter)
matches_data <- request(api_base_url) |> 
  req_url_path_append("matches", "2025-2026") |> 
  req_url_query(limit = 500) |>               # Optional limit parameter
  req_perform() |> 
  resp_body_raw() |>                          # Get the raw binary RDS stream
  unserialize()                               # Convert it back to a data.frame

# 2. Querying /table/ (Query Parameters)
table_data <- request(api_base_url) |> 
  req_url_path_append("table") |> 
  req_url_query(season = "2025-2026") |> 
  req_perform() |> 
  resp_body_raw() |> 
  unserialize()


library(dplyr)


# 2. Querying /table/ (Query Parameters)
table_data <- request(api_base_url) |> 
  req_url_path_append("table") |> 
  req_url_query(limit = 1000) |> 
    req_perform() |> 
  resp_body_raw() |> 
  unserialize()


seasons <- table_data |> 
  distinct(season) |> 
  pull() 



library(dplyr)
v1 <- nanoparquet::read_parquet("/home/seb/Downloads/v1.parquet")
v2 <- nanoparquet::read_parquet("/home/seb/Downloads/v2.parquet") |> 
  arrange(match_date, team_home)
