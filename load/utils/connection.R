# Setup connection pool

connect_pool <- function() {

  pool <<- pool::dbPool(
    duckdb::duckdb(),
    dbdir = ":memory:"
  )

  # Initialize DuckDB extensions and catalog
  # In production, consider moving this to a startup script or Dockerfile
  con <- poolCheckout(pool)
  dbExecute(con, "INSTALL ducklake; LOAD ducklake")
  dbExecute(con, "INSTALL icu")
  dbExecute(con, "INSTALL httpfs; LOAD httpfs")

  dbExecute(con, "SET s3_url_style='path'; SET s3_endpoint='s3-pergola-rustfs-dev.apps.pergola.cloud'")

  # Use environment variables for credentials
  db_conn_str <- sprintf(
    "ducklake:postgres:dbname=ducklake host=%s user=%s password=%s",
    Sys.getenv("POSTGRES_HOST", "localhost"),
    Sys.getenv("POSTGRES_USER"),
    Sys.getenv("POSTGRES_PASSWORD")
  )

  dbExecute(con, sprintf("ATTACH '%s' AS catalog (DATA_PATH 's3://%s', METADATA_SCHEMA 'ducklake'); USE catalog",
                          db_conn_str, Sys.getenv("S3_BUCKET")))
  poolReturn(con)


}
