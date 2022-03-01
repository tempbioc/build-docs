#' Build rOpenSci docs
#'
#' Builds custom rOpenSci pkgdown site from  a git remote, and store in
#' a zip file to be saved as a CI artifact.
#'
#' @rdname build
#' @param repo_url full URL of the git remote (used to customize the template)
#' @param subdir subdirectory with package repository
#' @param registry name of the registry that owns the package (not yet in)
#' @export
#' @examples \dontrun{
#' build_site('https://github.com/ropensci/magick')
#' }
build_site <- function(repo_url, subdir = "", registry = NULL){
  zipfile <- file.path(getwd(), 'docs.zip')
  # Clone the repo and cd in it
  src <- file.path(tempdir(), paste0(basename(repo_url), '-source'))
  gert::git_clone(repo_url, path = src, verbose = FALSE)
  pwd <- getwd()
  pkgdir <- normalizePath(file.path(src, subdir), mustWork = TRUE)
  on.exit(setwd(pwd), add = TRUE)
  setwd(pkgdir)

  # Some checks
  if(!file.exists('DESCRIPTION'))
    stop("Remote does not contain an R package")
  pkginfo <- as.data.frame(read.dcf('DESCRIPTION'))

  # Try to install missing sysdeps.
  # This only installs the first match; system_requirements may return many recursive sysdeps.
  # But most sysdeps are preinstalled for us anyway
  ubuntu <- gsub(" ", "-", tolower(substring(utils::osVersion,1,12)))
  tryCatch({
    aptline <- remotes::system_requirements(ubuntu)
    if(length(aptline) && !grepl('(libcurl|pandoc)', aptline[1])){
      system(aptline[1])
    }
    # Special case extra libs that we don't have in the base image
    extras <- grep('qgis|librdf0-dev', aptline, value = TRUE)
    lapply(extras, system)
  }, error = function(e){
    message("Problem looking for system requirements: ", e$message)
  })

  # Extra packages
  try(install_pkgdown_packages())
  Sys.setenv(R_REMOTES_NO_ERRORS_FROM_WARNINGS=TRUE)
  remotes::install_deps(dependencies = TRUE, upgrade = TRUE)
  remotes::install_local()

  # Website destination path
  pkg <- pkginfo$Package
  tmp <- file.path(tempdir(), pkg)
  unlink(tmp, recursive = TRUE)

  # Remove temp site in case of failure
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
  rotemplate::build_ropensci_docs(destination = tmp)
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
    apt_pkgs <- c(pkgdown_config$apt_packages)
    if(length(apt_pkgs)){
      system("apt-get update")
      system(paste("apt-get install -y", paste(apt_pkgs, collapse = " ")))
    }
  }
}
