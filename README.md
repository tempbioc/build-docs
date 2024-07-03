# Action: build-docs

This action is currently only enabled for the [ropensci universe](https://ropensci.r-universe.dev). It builds the pkgdown site from a git url and saves the entire site it in a zip file. It part of the [package build workflow](https://github.com/tempbioc/workflows/blob/master/build.yml) that runs for each package update in ropensci. The action automatically takes care of dependencies.

You can test it locally like this:

```
docker run -it ghcr.io/r-universe-org/build-docs "https://github.com/jeroen/jsonlite"
```
