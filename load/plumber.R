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
#* @serializer csv
function(season) {
  # Use parameterized query to prevent SQL injection
  query <- "SELECT * FROM marts.fct_match_stats WHERE season = ? ORDER BY match_date"
  dbGetQuery(pool, query, params = list(season))
}

#* @get /table/
#* @serializer csv
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