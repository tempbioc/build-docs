FROM runiverse/base

COPY . /rodocs
RUN R -e 'install.packages("remotes"); remotes::install_local("/rodocs"); install.packages("https://cran.r-project.org/src/contrib/Archive/pkgdown/pkgdown_1.6.1.tar.gz", repos = NULL)'

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
