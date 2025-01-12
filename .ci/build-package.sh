#!/bin/bash

# failure is a natural part of life
set -e -u -o pipefail

apt-get update
apt-get install \
    --no-install-recommends \
    -y \
    curl \
    texinfo \
    texlive-latex-recommended \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    qpdf

R CMD build ./r-pkg
