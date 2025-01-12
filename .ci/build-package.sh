#!/bin/bash

# failure is a natural part of life
set -e -u -o pipefail

sudo apt-get update
sudo apt-get install \
    --no-install-recommends \
    -y \
    curl \
    texinfo \
    texlive-latex-recommended \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    qpdf

R CMD build ./r-pkg
