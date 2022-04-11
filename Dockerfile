FROM runiverse/base

COPY . /rodocs
RUN R -e 'install.packages("remotes"); remotes::install_local("/rodocs")'

# Remove when rspm has 4.2 binaries
RUN R -e 'remotes::install_github("r-lib/ragg")'

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
