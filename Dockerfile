FROM rstudio/plumber

RUN apt-get update -qq && apt-get install -y libssl-dev libcurl4-gnutls-dev libpng-dev pandoc

RUN R -e "install.packages(c('readr', 'dplyr', 'recipes', 'parsnip', 'workflows', 'ranger'))"

COPY API.R API.R
COPY data/train.csv data/train.csv

EXPOSE 8000

ENTRYPOINT ["R", "-e", \
    "pr <- plumber::plumb('API.R'); pr$run(host='0.0.0.0', port=8000)"]
