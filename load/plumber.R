library(plumber)
library(duckdb)
library(dplyr)
library(pool)

source('utils/connection.R')

connect_pool()


#* @apiTitle Bundesliga Stats API
#* @apiDescription Learning plumber, rhino and the newest practices with Shiny
#* @apiLicense list(name = "Apache 2.0", url = "https://www.apache.org/licenses/LICENSE-2.0.html")
#* @apiVersion 1.0.1

#* @get /matches/<season>
#* @serializer rds
#* Match statistics
#* Get match statistics (points, goals, xg, pi scores). Supply a season in the format start-end (e.g. 2025-2026) to filter seasons of interest.
function(season) {
  # Use parameterized query to prevent SQL injection
  query <- "SELECT * FROM marts.fct_match_stats WHERE season = ? ORDER BY match_date"
  dbGetQuery(pool, query, params = list(season))
}

#* @get /table/
#* @serializer rds
#* Download tables for selected season
#* Download current or historic standings and statistics. Supply a season in the format start-end (e.g. 2025-2026) to filter seasons of interest.
function(season = NULL) {
  if (is.null(season) || season == "") {
    query <- "SELECT * FROM marts.fct_season_team_stats"
    dbGetQuery(pool, query)
  } else {
    # 2. Use parameterized query if season is provided
    query <- "SELECT * FROM marts.fct_season_team_stats WHERE season = ?"
    dbGetQuery(pool, query, params = list(season))
  }
}

#* @get /season_stats/
#* @serializer json
#* Extended season stats (home/away)
#* Additional statistics separated by venue (home/away). Supply a season in the format start-end (e.g. 2025-2026) to filter seasons of interest. 
function(season = NULL) {
  if (is.null(season) || season == "") {
    query <- "SELECT * FROM marts.fct_season_team_stats_home_away"
    dbGetQuery(pool, query)
  } else {
    # 2. Use parameterized query if season is provided
    query <- "SELECT * FROM marts.fct_season_team_stats_home_away WHERE season = ?"
    dbGetQuery(pool, query, params = list(season))
  }
}