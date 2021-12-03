FROM runiverse/base

COPY . /rodocs
RUN R -e 'install.packages("remotes"); remotes::install_local("/rodocs")'

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
