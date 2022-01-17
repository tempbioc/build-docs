FROM runiverse/base

COPY . /rodocs
RUN R -e 'install.packages("remotes"); remotes::install_local("/rodocs")'

# Temp workaround for https://github.com/ropensci-org/rotemplate/issues/76
RUN R -e 'remotes::install_version("pkgdown", "2.0.1")'

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
