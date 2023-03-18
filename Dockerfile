FROM ghcr.io/r-universe-org/base-image

COPY . /rodocs
RUN R -e 'install.packages("remotes"); remotes::install_local("/rodocs")'

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
