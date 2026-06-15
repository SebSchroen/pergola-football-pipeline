# Setup connection pool

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
