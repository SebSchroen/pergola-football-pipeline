library(plumber)
library(duckdb)
library(pool)

source('utils/connection.R')

# Assign pool cleanly to avoid global environment pollution
pool <- connect_pool()

# Helper function to validate season format (YYYY-YYYY)
is_valid_season <- function(season) {
  grepl("^\\d{4}-\\d{4}$", season)
}

# Helper function to parse and validate limit parameter
parse_limit <- function(limit, default = 1000, max_limit = 10000) {
  if (is.null(limit) || limit == "") {
    return(default)
  }
  parsed <- as.integer(limit)
  if (is.na(parsed) || parsed <= 0) {
    return(default)
  }
  return(min(parsed, max_limit))
}

#* @apiTitle Bundesliga Stats API
#* @apiDescription Learning plumber, rhino and the newest practices with Shiny
#* @apiLicense list(name = "Apache 2.0", url = "https://www.apache.org/licenses/LICENSE-2.0.html")
#* @apiVersion 1.0.1

#* @filter logger
#* Log incoming requests
function(req) {
  # Capture request details
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  method <- req$REQUEST_METHOD
  path <- req$PATH_INFO
  query <- req$QUERY_STRING
  ip <- req$REMOTE_ADDR
  
  # Format query string if present
  query_str <- if (nchar(query) > 0) paste0("?", query) else ""
  
  # Print log message to stdout
  cat(sprintf("[%s] %s - %s %s%s\n", timestamp, ip, method, path, query_str))
  
  # Forward request to the next handler
  forward()
}

#* @get /matches/<season>
#* @serializer rds
#* Match statistics
#* Get match statistics (points, goals, xg, pi scores). Supply a season in the format start-end (e.g. 2025-2026) to filter seasons of interest.
#* @param limit Maximum number of records to return (default 1000, max 10000)
function(season, limit = NULL, res) {
  if (!is_valid_season(season)) {
    res$status <- 400
    return(list(error = "Invalid season format. Expected YYYY-YYYY (e.g., 2025-2026)."))
  }
  
  parsed_limit <- parse_limit(limit)
  query <- "SELECT * FROM marts.fct_match_stats WHERE season = ? ORDER BY match_date LIMIT ?"
  dbGetQuery(pool, query, params = list(season, parsed_limit))
}

#* @get /table
#* @serializer rds
#* Download tables for selected season
#* Download current or historic standings and statistics. Supply a season in the format start-end (e.g. 2025-2026) to filter seasons of interest.
#* @param limit Maximum number of records to return (default 1000, max 10000)
function(season = NULL, limit = NULL, res) {
  parsed_limit <- parse_limit(limit)
  
  if (is.null(season) || season == "") {
    query <- "SELECT * FROM marts.fct_season_team_stats LIMIT ?"
    dbGetQuery(pool, query, params = list(parsed_limit))
  } else {
    if (!is_valid_season(season)) {
      res$status <- 400
      return(list(error = "Invalid season format. Expected YYYY-YYYY (e.g., 2025-2026)."))
    }
    query <- "SELECT * FROM marts.fct_season_team_stats WHERE season = ? LIMIT ?"
    dbGetQuery(pool, query, params = list(season, parsed_limit))
  }
}

#* @get /season_stats
#* @serializer rds
#* Extended season stats (home/away)
#* Additional statistics separated by venue (home/away). Supply a season in the format start-end (e.g. 2025-2026) to filter seasons of interest.
#* @param limit Maximum number of records to return (default 1000, max 10000)
function(season = NULL, limit = NULL, res) {
  parsed_limit <- parse_limit(limit)
  
  if (is.null(season) || season == "") {
    query <- "SELECT * FROM marts.fct_season_team_stats_home_away LIMIT ?"
    dbGetQuery(pool, query, params = list(parsed_limit))
  } else {
    if (!is_valid_season(season)) {
      res$status <- 400
      return(list(error = "Invalid season format. Expected YYYY-YYYY (e.g., 2025-2026)."))
    }
    query <- "SELECT * FROM marts.fct_season_team_stats_home_away WHERE season = ? LIMIT ?"
    dbGetQuery(pool, query, params = list(season, parsed_limit))
  }
}