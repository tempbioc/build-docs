#' Build rOpenSci docs
#'
#' Builds custom rOpenSci pkgdown site from  a git remote.
#'
#' @rdname build
#' @param repo_url full URL of the git remote (used to customize the template)
#' @param deploy_url URL where the sites will be hosted
#' @export
#' @examples \dontrun{
#' build_site('https://github.com/ropensci/magick', 'https://docs.ropensci.org/magick')
#' }
build_site <- function(repo_url, deploy_url){
  zipfile <- file.path(getwd(), 'docs.zip')
  # Clone the repo and cd in it
  src <- tempfile()
  gert::git_clone(repo_url, path = src, verbose = FALSE)
  pwd <- getwd()
  on.exit(setwd(pwd), add = TRUE)
  setwd(src)

  # Some checks
  if(!file.exists('DESCRIPTION'))
    stop("Remote does not contain an R package")
  pkginfo <- as.data.frame(read.dcf('DESCRIPTION'))

  if(file.exists('.norodocs'))
    stop("Package contains a '.norodocs' file, not generating docs")

  # From pkgdown build_home_index()
  home_files <- c("index.Rmd", "README.Rmd", "index.md", "README.md")
  home_files <- Filter(file.exists, home_files)
  if(!length(home_files))
    stop("Package does not contain an index.(r)md or README.(r)md file")

  # This is done by Rprofile in runiverse/base image already
  #utils::setRepositories(ind = 1:2)
  #my_repo <- Sys.getenv("UNIVERSE_REPO")
  #if(nchar(my_repo))
  #  options(repos = c("universe" = my_repo, getOption('repos')))

  # Extra packages
  try(install_pkgdown_packages())
  Sys.setenv(R_REMOTES_NO_ERRORS_FROM_WARNINGS=TRUE)
  remotes::install_deps(dependencies = TRUE, upgrade = TRUE)
  remotes::install_local()

  # Hack the readme
  pkg <- pkginfo$Package
  lapply(home_files, modify_ropensci_readme, pkg = pkg, repo_url = repo_url)

  # Build the website
  title <- sprintf("rOpenSci: %s", pkg)
  tmp <- file.path(tempdir(), pkg)
  template <- list(
    params = list(
      docsearch = list(
        api_key = '799829e946e1f0f9cd5b5a782c6316b9',
        index_name = paste0('ropensci-', tolower(pkg))
      )
    )
  )
  if(!isTRUE(grepl('ropenscilabs', repo_url))){
    template$package = "rotemplate"

    # Hack: pkgdown doesn't seem to override packages that set: template:path
    template$path = system.file("pkgdown/templates", package='rotemplate')
  }

  unlink(tmp, recursive = TRUE)

  # Remove temp site in case of failure
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
  Sys.setenv(NOT_CRAN="true")
  pkgdown::build_site(devel = FALSE, preview = FALSE, install = FALSE, override =
    list(destination = tmp, title = title, url = deploy_url, template = template,
         development = list(mode = 'release')))
  file.create(file.path(tmp, '.nojekyll'))

  # Save some info about the repo
  head <- gert::git_log(max = 1, repo = src)
  jsonlite::write_json(list(commit = as.list(head), repo = repo_url, pkg = pkg),
                       file.path(tmp, 'info.json'), pretty = TRUE, auto_unbox = TRUE)

  # Move site to final location
  setwd(dirname(tmp))
  zip::zip(zipfile, basename(tmp))
  invisible(zipfile)
}

install_pkgdown_packages <- function(){
  if(file.exists('_pkgdown.yml')){
    pkgdown_config <- yaml::read_yaml('_pkgdown.yml')
    extra_pkgs <- c(pkgdown_config$extra_packages)
    is_github <- grepl('/', extra_pkgs)
    cran_pkgs <- extra_pkgs[!is_github]
    gh_pkgs <- extra_pkgs[is_github]
    if(length(cran_pkgs)){
      remotes::install_cran(cran_pkgs, upgrade = FALSE)
    }
    if(length(gh_pkgs)){
      remotes::install_github(gh_pkgs, upgrade = FALSE)
    }
  }
}
