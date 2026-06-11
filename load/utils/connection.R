# Setup connection pool

connect_pool <- function() {

  pool <- pool::dbPool(
    duckdb(),
    dbdir = ":memory:"
  )

  # Initialize DuckDB extensions and catalog
  # In production, consider moving this to a startup script or Dockerfile
  dbExecute(pool, "INSTALL ducklake; LOAD ducklake")
  dbExecute(pool, "INSTALL icu")
  dbExecute(pool, "INSTALL httpfs; LOAD httpfs")

  dbExecute(pool, "SET s3_url_style='path'; SET s3_endpoint='s3-pergola-rustfs-dev.apps.pergola.cloud'")

  # Use environment variables for credentials
  db_conn_str <- sprintf(
    "ducklake:postgres:dbname=ducklake host=%s user=%s password=%s",
    Sys.getenv("POSTGRES_HOST", "localhost"),
    Sys.getenv("POSTGRES_USER"),
    Sys.getenv("POSTGRES_PASSWORD")
  )

  dbExecute(pool, sprintf("ATTACH '%s' AS catalog (DATA_PATH 's3://%s', METADATA_SCHEMA 'ducklake'); USE catalog",
                          db_conn_str, Sys.getenv("S3_BUCKET")))


}
