# Use a lightweight Python image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install dbt and dependencies
RUN pip install --no-cache-dir dbt-duckdb

# Copy project files
COPY . .

# Make entrypoint script executable
RUN chmod +x docker-entrypoint.sh

# Set entrypoint script
ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["run"]
