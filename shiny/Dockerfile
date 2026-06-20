FROM rocker/shiny:latest


RUN apt-get update && apt-get install -y \
    cmake \
    git \
    libgit2-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    libcairo2-dev \
    libfontconfig1-dev \
    libssl-dev \
    libxml2-dev \
    libudunits2-dev \
    libgdal-dev \
    pandoc \
    pandoc-data \
    libuv1-dev \
    && rm -rf /var/lib/apt/lists/*

# 2. Set up renv
WORKDIR /project

COPY shiny/renv.lock .
COPY shiny/renv/activate.R renv/activate.R


COPY shiny/.Rprofile .Rprofile

# 3. Restore packages (this uses the exact versions from renv.lock)
RUN R -e "renv::restore()"

# 4. Copy app files
COPY shiny/app.R app.R
COPY shiny/R/ R/

EXPOSE 3838

# 5. Run app
RUN touch .httr-oauth
CMD ["Rscript", "-e", "shiny::runApp('app.R', host='0.0.0.0', port=3838)"]