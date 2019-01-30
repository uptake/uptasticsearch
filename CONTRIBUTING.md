# Contributing to uptasticsearch

The primary goal of this guide is to help you contribute to `uptasticsearch` as quickly and as easily possible. It's secondary goal is to document important information for maintainers.

#### Table of contents

* [Creating an Issue](#issues)
* [Submitting a Pull Request](#prs)
* [Running Tests Locally](#testing)
* [Releasing to CRAN (for maintainer)](#cran)

## Creating an Issue <a name="issues"></a>

To report bugs, request features, or ask questions about the structure of the code, please [open an issue](https://github.com/UptakeOpenSource/uptasticsearch/issues).

### Bug Reports

If you are reporting a bug, please describe as many as possible of the following items in your issue:

- your operating system (type and version)
- your version of R
- your version of `uptasticsearcht`

The text of your issue should answer the question "what did you expect `uptasticsearch` to do and what did it actually do?".

We welcome any and all bug reports. However, we'll be best able to help you if you can reduce the bug down to a **minimum working example**. A **minimal working example (MWE)** is the minimal code needed to reproduce the incorrect behavior you are reporting. Please consider the [stackoverflow guide on MWE authoring](https://stackoverflow.com/help/mcve).

If you're interested in submitting a pull request to address the bug you're reporting, please indicate that in the issue.

### Feature Requests

We welcome feature requests, and prefer the issues page as a place to log and categorize them. If you would like to request a new feature, please open an issue there and add the `enhancement` tag.

Good feature requests will note all of the following:

- what you would like to do with `uptasticsearch`
- how valuable you think being able to do that with `uptasticsearch` would be
- sample code showing how you would use this feature if it was added

If you're interested in submitting a pull request to address the bug you're reporting, please indicate that in the issue.

## Submitting a Pull Request <a name="prs"></a>

We welcome [pull requests](https://help.github.com/articles/about-pull-requests/) from anyone interested in contributing to `uptasticsearch`. This section describes best practices for submitting PRs to this project.

If you are interested in making changes that impact the way `uptasticsearch` works, please [open an issue](#issues) proposing what you would like to work on before you spend time creating a PR.

If you would like to make changes that do not directly impact how `uptasticsearch` works, such as improving documentation, adding unit tests, or minor bug fixes, please feel free to implement those changes and directly create PRs.

If you are not sure which of the preceding conditions applies to you, open an issue. We'd love to hear your idea!

To submit a PR, please follow these steps:

1. Fork `uptasticsearch` to your GitHub account
2. Create a branch on your fork and add your changes
3. If you are changing or adding to the R code in the package, add unit tests confirming that your code works as expected
3. When you are ready, click "Compare & Pull Request". Open A PR comparing your branch to the `master` branch in this repo
4. In the description section on your PR, please indicate the following:
    - description of what the PR is trying to do and how it improves `uptasticsearch`
    - links to any open [issues](https://github.com/UptakeOpenSource/uptasticsearch/issues) that your PR is addressing

We will try to review PRs promptly and get back to you within a few days.

## Running Tests Locally <a name="testing"></a>

When developing on this package, you may want to run Elasticsearch locally to speed up the testing cycle. We've provided some gross bash scripts at the root of this repo to help!

To run the code below, you will need [Docker](https://www.docker.com/). Note that I've passed an argument to `setup_local.sh` indicating the major version of ES I want to run. If you don't do that, this script will just run the most recent major version of Elasticsearch. Look at the source code of `setup_local.sh` for a list of the valid arguments.

```
# Start up Elasticsearch on localhost:9200 and seed it with data
./setup_local.sh 5.5

# Run tests
make test_r

# Get test coverage and generate coverage report
make coverage_r

# Tear down the container and remove testing files
./cleanup_local.sh
```

## Releasing to CRAN (for maintainer) <a name="cran"></a>

Once substantial time has passed or significant changes have been made to `uptasticsearch`, a new release should be pushed to [CRAN](https://cran.r-project.org). 

This is the exclusively the responsibility of the package maintainer, but is documented here for our own reference and to reflect the consensus reached between the maintainer and other contributors.

This is a manual process, with the following steps.

### Open a PR 

Open a PR with a branch name `release/v0.0.0` (replacing 0.0.0 with the actual version number).

Add a section for this release to `NEWS.md`.  This file details the new features, changes, and bug fixes that occured since the last version.  

Add a section for this release to `cran-comments.md`. This file holds details of our submission comments to CRAN and their responses to our submissions.  

Change the `Version:` field in `DESCRIPTION` to the official version you want on CRAN (should not have a trailing `.9000`).

This project uses Github Pages to host a documentation site:

https://uptakeopensource.github.io/uptasticsearch/

This documentation needs to be periodically, manually updated. To generate the new files for an "update the site" PR, just run the following:

```
make gh_pages
```

Note that for now, the R project is more mature and that is the only docs we host on the Github Pages site.

### Submit to CRAN

Build the package tarball by running the following

```
make build_r
```

Go to https://cran.r-project.org/submit.html and submit this new release! In the upload section, upload the tarball you just built.

### Handle feedback from CRAN

The maintainer will get an email from CRAN with the status of the submission. 

If the submission is not accepted, do whatever CRAN asked you to do. Update `cran-comments.md` with some comments explaining the requested changes. Rebuild the `pkgdown` site. Repeat this process until the package gets accepted.

### Merge the PR

Once the submission is accepted, great! Update `cran-comments.md` and merge the PR.

### Create a Release on GitHub

We use [the releases section](https://github.com/UptakeOpenSource/uptasticsearch/releases) in the repo to categorize certain important commits as release checkpoints. This makes it easier for developers to associate changes in the source code with the release history on CRAN, and enables features like `devtools::install_github()` for old versions.

Navigate to https://github.com/UptakeOpenSource/uptasticsearch/releases/new. Click the dropdown in the "target" section, then click "recent commits". Choose the latest commit for the release PR you just merged. This will automatically create a [git tag](https://git-scm.com/book/en/v2/Git-Basics-Tagging) on that commit and tell Github which revision to build when people ask for a given release.

Add some notes explaining what has changed since the previous release.

### Open a new PR to begin development on the next version

Now that everything is done, the last thing you have to do is move the repo ahead of the version you just pushed to CRAN.

Make a PR that adds a `.9000` on the end of the version you just released. This is a common practice in open source software development. It makes it obvious that the code in source control is newer than what's available from package managers, but doesn't interfere with the [semantic versioning](https://semver.org/) components of the package version.
