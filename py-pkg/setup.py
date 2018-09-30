#!/usr/bin/env python
# -*- coding: utf-8 -*-
import json
import os
import re
from setuptools import find_packages
from setuptools import setup
import subprocess
import datetime

CURRENT_VERSION = "0.1.0"

#########################

# Packages used
documentation_packages = [
    "sphinx",
    "sphinx_rtd_theme",
    "sphinxcontrib-napoleon",
    "sphinxcontrib-programoutput"
]
regular_packages = [
    'pandas',
    'requests',
    'tqdm'
]
testing_packages = [
    'pytest',
    'mock'
]

# This is where the magic happens
setup(name='uptasticsearch',
      version=CURRENT_VERSION,
      description="Get Data Frame Representations of 'Elasticsearch' Results",
      author='Nick Paras',
      author_email='nickgp@gmail.com',
      url='https://github.com/UptakeOpenSource/uptasticsearch',
      packages=find_packages(),
      install_requires=regular_packages + documentation_packages + testing_packages,
      include_package_data=True,
      extras_require={
          'doc': documentation_packages,
          'all': regular_packages + documentation_packages,
      },
      zip_safe = False
      )
