FROM rocker/tidyverse:4.5.3

# 1. Install system dependencies (required for compiling many R packages)
RUN apt-get update -qq && apt-get install --no-install-recommends -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    xz-utils \         
    libsodium-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Tell renv to use pre-compiled Linux binaries (Ubuntu 22.04 Jammy)
# This avoids compiling packages like duckdb and Rcpp from source.
ENV RENV_CONFIG_REPOS_OVERRIDE="https://packagemanager.posit.co/cran/__linux__/jammy/latest"


# 2. Install renv
ENV RENV_VERSION=1.1.6
RUN R -e "install.packages('remotes', repos='https://cloud.r-project.org')" && \
    R -e "remotes::install_version('renv', version='${RENV_VERSION}', repos='https://cloud.r-project.org')"

# 3. Copy ONLY renv.lock first (for caching)
COPY renv.lock renv.lock

# 4. Restore the R environment
# This step will be cached by Docker unless renv.lock changes
RUN R -e "renv::restore()"

# 5. Copy the actual plumber API code
COPY plumber.R plumber.R

#COPY .Renviron .Renviron
EXPOSE 8000

CMD ["R", "-e", "plumber2::api('plumber.R') |> plumber2::api_run(host='0.0.0.0', port=8000)"]