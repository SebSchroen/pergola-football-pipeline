FROM rocker/shiny-verse:4.6.0



# 2. Set up renv
WORKDIR /project

COPY shiny-rhino/renv.lock .
COPY shiny-rhino/renv/activate.R renv/activate.R


COPY shiny-rhino/.Rprofile .Rprofile

# 3. Restore packages (this uses the exact versions from renv.lock)
RUN R -e "renv::restore()"

# 4. Copy app files
COPY shiny-rhino/. .

EXPOSE 3838


# 5. Run app
RUN touch .httr-oauth
CMD ["Rscript", "-e", "shiny::runApp('app.R', host='0.0.0.0', port=3838)"]