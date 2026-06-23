library(plumber2)
library(duckdb)
library(pool)


connect_pool <- function() {
  # Use environment variables for credentials
  db_conn_str <- sprintf(
    "ducklake:postgres:dbname=ducklake host=%s user=%s password=%s",
    Sys.getenv("POSTGRES_HOST", "localhost"),
    Sys.getenv("POSTGRES_USER"),
    Sys.getenv("POSTGRES_PASSWORD")
  )
  s3_bucket <- Sys.getenv("S3_BUCKET")

  # Create the pool and initialize each connection as it is created
  pool::dbPool(
    duckdb::duckdb(),
    dbdir = ":memory:",
    onCreate = function(con) {
      DBI::dbExecute(con, "INSTALL ducklake; LOAD ducklake")
      DBI::dbExecute(con, "INSTALL icu")
      DBI::dbExecute(con, "INSTALL httpfs; LOAD httpfs")
      DBI::dbExecute(con, "SET s3_url_style='path'; SET s3_endpoint='s3-pergola-rustfs-dev.apps.pergola.cloud'")
      DBI::dbExecute(con, sprintf("ATTACH '%s' AS catalog (DATA_PATH 's3://%s', METADATA_SCHEMA 'ducklake'); USE catalog",
                                  db_conn_str, s3_bucket))
    }
  )
}

# Assign pool cleanly to avoid global environment pollution
pool <- connect_pool()

# Helper function to validate season format (YYYY-YYYY)
is_valid_season <- function(season) {
  grepl("^\\d{4}-\\d{4}$", season)
}

#* @title Bundesliga Stats API
#* @description Learning plumber, rhino and the newest practices with Shiny
#* @license list(name = "Apache 2.0", url = "https://www.apache.org/licenses/LICENSE-2.0.html")
#* @version 1.0.1

#* Match statistics
#* 
#* Match statistics (points, goals, xg, pi scores). Supply a season in the format start-end (e.g. 2025-2026) to filter seasons of interest.
#* 
#* @get /matches/<season>
#* 
#* @serializer rds
#* @param season:string A season string in the format YYYY-YYYY (e.g., 2025-2026).
function(season) {
  if (!is_valid_season(season)) {
    res$status <- 400
      abort_bad_request(
      "Invalid season format. Expected YYYY-YYYY (e.g., 2025-2026)."
    )
  }
  
  query <- "SELECT DISTINCT * FROM marts.fct_match_stats WHERE season = ? ORDER BY match_date"
  dbGetQuery(pool, query, params = list(season))
}


#* Download tables for selected season
#* 
#* Download current or historic standings and statistics. Supply a season in the format start-end (e.g. 2025-2026) to filter seasons of interest.
#* 
#* @get /table/<season>
#* @serializer rds
#* @param season:string A season string in the format YYYY-YYYY (e.g., 2025-2026).
function(season) {
  
  if (is.null(season) || season == "") {
    query <- "SELECT * FROM marts.fct_season_team_stats"
    dbGetQuery(pool, query)
  } else {
    if (!is_valid_season(season)) {
      res$status <- 400
      abort_bad_request(
      "Invalid season format. Expected YYYY-YYYY (e.g., 2025-2026)."
    )
    }
    query <- "SELECT DISTINCT * FROM marts.fct_season_team_stats WHERE season = ?"
    dbGetQuery(pool, query, params = list(season))
  }
}


#* Extended season stats (home/away)
#* 
#* Additional statistics separated by venue (home/away). Supply a season in the format start-end (e.g. 2025-2026) to filter seasons of interest.
#* 
#* @get /season_stats/<season>
#* 
#* @serializer rds
#* @param season:string A season string in the format YYYY-YYYY (e.g., 2025-2026).
function(season) {
  
  if (is.null(season) || season == "") {
    query <- "SELECT DISTINCT * FROM marts.fct_season_team_stats_home_away"
    dbGetQuery(pool, query)
  } else {
    if (!is_valid_season(season)) {
      res$status <- 400
      abort_bad_request(
      "Invalid season format. Expected YYYY-YYYY (e.g., 2025-2026)."
    )
    }
    query <- "SELECT DISTINCT * FROM marts.fct_season_team_stats_home_away WHERE season = ?"
    dbGetQuery(pool, query, params = list(season))
  }
}

#* Full Pi Ratings history
#* 
#* Full historical Pi Ratings starting Season 2006/2007.
#* 
#* @get /ratings
#* 
#* @serializer rds
#* 
#* @query season:string A season string in the format YYYY-YYYY (e.g., 2025-2026).
function(query) {
  
  if (!is.null(query$season) && query$season != "") {
    if (!is_valid_season(query$season)) {
      abort_bad_request(
        "Invalid season format. Expected YYYY-YYYY (e.g., 2025-2026)."
      )
    }
    
    sql_query <- "SELECT DISTINCT * FROM stg.stg_ratings_history WHERE season = ?"
    dbGetQuery(pool, sql_query, params = list(query$season))
    
  } else {
    sql_query <- "SELECT DISTINCT * FROM stg.stg_ratings_history"
    print(sql_query)
    dbGetQuery(pool, sql_query)
  }
}

#* Club header data and mapping table
#* 
#* Full historical Pi Ratings starting Season 2006/2007.
#* 
#* @get /masterdata
#* 
#* @serializer rds
function() {
  query <- "SELECT DISTINCT * FROM stg.masterdata"
  dbGetQuery(pool, query)

}
