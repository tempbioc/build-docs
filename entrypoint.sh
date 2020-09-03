#!/bin/bash -l
set -e
Rscript -e "rodocs::build_site('$1', '$2')"
echo "Action complete!"
