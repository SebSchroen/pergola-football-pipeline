library(duckdb)
library(dplyr)
readRenviron(".Renviron")

con <- dbConnect(duckdb(), dbdir=":memory:")


dbExecute(con, "INSTALL ducklake; LOAD ducklake")
dbExecute(con, "INSTALL icu")
dbExecute(con, "INSTALL httpfs; LOAD httpfs")

dbExecute(con, "SET s3_url_style='path'; SET s3_endpoint='s3-pergola-rustfs-dev.apps.pergola.cloud'" )



fixture_history <- dbGetQuery(con, "SELECT file_last_modified FROM read_parquet('s3://football/stg/stg_fixture_history/*92f.parquet', union_by_name= true)") |> 
  arrange(date, team_home)


ratings_history <- dbGetQuery(con, "SELECT * FROM read_parquet('s3://football/stg/stg_ratings_history/*d63.parquet', union_by_name= true)") |> 
  arrange(date, team)



dbExecute(con, "ATTACH 'ducklake:postgres:dbname=ducklake host=localhost user=username password=password' AS catalog (DATA_PATH 's3://football-dev', METADATA_SCHEMA 'ducklake', OVERRIDE_DATA_PATH True); USE catalog")




understat = dbGetQuery(con, "SELECT * FROM __ducklake_metadata_catalog.ducklake.ducklake_table")


fixture = dbGetQuery(con, "SELECT * FROM raw.fixture_history  WHERE season = '2025-2026'")

md = dbGetQuery(con, "SELECT * FROM stg.masterdata")



test = fixture |> left_join(md, by = c("team_home" = "footballdata")) |> 
  left_join(understat, by = c("understat" = "team_home", "date"))



stuff = dbGetQuery(con, "SELECT * FROM marts.INFORMATION_SCHEMA  WHERE season = '2023-2024'")


head(stuff)

library(ggplot2)

ggplot(data=stuff, aes(x=points, y = xpts, label = team)) + geom_text() +
  geom_abline(slope = 1, intercept = 0) +
  labs(x="Points", y = "Expected Points")

stats = dbGetQuery(con, "SELECT * FROM intermediate.int_team_match_days WHERE season = '2025-2026'")


stuff = dbGetQuery(con, "SELECT * FROM marts.fct_match_stats  WHERE season = '2023-2024' ORDER BY match_date")
