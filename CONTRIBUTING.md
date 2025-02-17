# Contributing to uptasticsearch

The primary goal of this guide is to help you contribute to `uptasticsearch` as quickly and as easily possible. It's secondary goal is to document important information for maintainers.

#### Table of contents

* [Creating an Issue](#issues)
* [Submitting a Pull Request](#prs)
* [Testing Strategy](#testing)
    - [GitHub Actions](#gha)
    - [Running tests locally](#testing-local)]
        - [Checking code style](#lint)
* [Releases](#releases)

## Creating an Issue <a name="issues"></a>

To report bugs, request features, or ask questions about the structure of the code, please [open an issue](https://github.com/uptake/uptasticsearch/issues).

### Bug Reports

If you are reporting a bug, please describe as many as possible of the following items in your issue:

- your operating system (type and version)
- your version of R
- your version of `uptasticsearch`

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
3. When you are ready, click "Compare & Pull Request". Open A PR comparing your branch to the `main` branch in this repo
4. In the description section on your PR, please indicate the following:
    - description of what the PR is trying to do and how it improves `uptasticsearch`
    - links to any open [issues](https://github.com/uptake/uptasticsearch/issues) that your PR is addressing

We will try to review PRs promptly and get back to you within a few days.

## Testing Strategy <a name="testing"></a>

### GitHub Actions <a name="gha"></a>

This project uses [GitHub Actions](https://github.com/features/actions) to run a variety of tests on every build.

Each build actually runs many sub-builds. Those sub-builds run once for each combination of:

* programming language
* Elasticsearch version

As of this writing, this project has clients in one programming language: [R](./r-pkg).

The set of Elasticsearch versions this project tests against changes regularly as [new Elasticsearch versions are released](https://www.elastic.co/downloads/past-releases#elasticsearch). The strategy in this project is to test against the following Elasticsearch versions:

> `uptasticsearch` is tested against the most recent release in every major release stream from 1.x onwards

> `uptasticsearch` is tested against the most recent maintenance release of the first and last minor releases on the prior stable version

> `uptasticsearch` is tested against the most recent maintenance release on every minor release in the release stream of the current stable version

> `uptasticsearch` may be tested against specific additional intermediate versions if bugs are found in the interaction between `uptasticsearch` and those versions

So, for example, as of January 2025 that meant we tested against:

* 1.7.6
* 2.4.6
* 5.6.16
* 6.0.1
* 6.8.15
* 7.0.1
* 7.1.1
* 7.2.1
* 7.3.2
* 7.4.2
* 7.5.2
* 7.6.2
* 7.7.1
* 7.8.1
* 7.9.3
* 7.10.2
* 7.11.2
* 7.12.1

You may notice that this strategy means that `uptasticsearch` is tested for backwards compatibility with Elasticsearch versions which have already reached [End-of-Life](https://www.elastic.co/support/eol). For example, support for Elasticsearch 1.7.x officially ended in January 2017.
We test these old versions because we know of users whose companies still run those versions, and for whom Elasticsearch upgrades are prohibitively expensive.
In general, upgrades across major versions pre-6.x [require a full cluster restart](https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-upgrade.html).

### Running Tests Locally <a name="testing-local"></a>

When developing on this package, you may want to run Elasticsearch locally to speed up the testing cycle. We've provided some gross bash scripts at the root of this repo to help!

To run the code below, you will need [Docker](https://www.docker.com/). Note that I've passed an argument to `setup_local.sh` indicating the version of Elasticsearch I want to run. Look at the source code of `setup_local.sh` for a list of the valid arguments.

```shell
# Start up Elasticsearch on localhost:9200 and seed it with data
./setup_local.sh 7.12.1

# Run tests
make test

# Get test coverage and generate coverage report
make coverage

# Tear down the container and remove testing files
./cleanup_local.sh
```

### Checking code style

The R package's code style is tested with `{lintr}`. To check the code locally, run the following

```shell
Rscript .ci/lint-r-code.R $(pwd)
```

## Releases <a name="releases"></a>

This section is intended for maintainers. It describes how to prepare an `uptasticsearch` release.

### CRAN

Once substantial time has passed or significant changes have been made to `uptasticsearch`, a new release should be pushed to [CRAN](https://cran.r-project.org).

This is the exclusively the responsibility of the package maintainer, but is documented here for our own reference and to reflect the consensus reached between the maintainer and other contributors.

This is a manual process, with the following steps.

**Open a Pull Request**

Open a PR with a branch name `release/v0.0.0` (replacing 0.0.0 with the actual version number).

Add a section for this release to `NEWS.md`.  This file details the new features, changes, and bug fixes that occurred since the last version.

Add a section for this release to `cran-comments.md`. This file holds details of our submission comments to CRAN and their responses to our submissions.

Change the `Version:` field in `DESCRIPTION` to the official version you want on CRAN (should not have a trailing `.9000`).

This project uses GitHub Pages to host a documentation site:

https://uptake.github.io/uptasticsearch/

**Submit to CRAN**

Build the package tarball by running the following

```shell
make build
```

Go to https://cran.r-project.org/submit.html and submit this new release! In the upload section, upload the tarball you just built.

**Handle feedback from CRAN**

The maintainer will get an email from CRAN with the status of the submission.

If the submission is not accepted, do whatever CRAN asked you to do. Update `cran-comments.md` with some comments explaining the requested changes. Rebuild the `pkgdown` site. Repeat this process until the package gets accepted.

**Merge the Pull Request**

Once the submission is accepted, great! Update `cran-comments.md` and merge the PR.

**Create a Release on GitHub**

We use [the releases section](https://github.com/uptake/uptasticsearch/releases) in the repo to categorize certain important commits as release checkpoints. This makes it easier for developers to associate changes in the source code with the release history on CRAN, and enables features like `remotes::install_github()` for old versions.

Navigate to https://github.com/uptake/uptasticsearch/releases/new. Click the dropdown in the "target" section, then click "recent commits". Choose the latest commit for the release PR you just merged. This will automatically create a [git tag](https://git-scm.com/book/en/v2/Git-Basics-Tagging) on that commit and tell Github which revision to build when people ask for a given release.

Add some notes explaining what has changed since the previous release.

### conda-forge

The R project is also released to `conda-forge`, under the name `r-uptasticsearch`.

`conda-forge` releases can only be done after releasing to CRAN. The details of `r-uptasticsearch` are managed in https://github.com/conda-forge/r-uptasticsearch-feedstock.

When a new version of the package is released to CRAN, `conda-forge`'s infrastructure will automatically create a pull request and update the recipe there. Merging that pull request will publish the new version to `conda-forge`.

In case you need to make bigger changes to the recipe, see the `conda-forge` documentation:

* [writing meta.yml files](https://docs.conda.io/projects/conda-build/en/latest/resources/define-metadata.html)
* [updates to CRAN-based R recipes](https://conda-forge.org/docs/maintainer/updating_pkgs.html)

### Open a new PR to begin development on the next version

Now that everything is done, the last thing you have to do is move the repo ahead of the version you just pushed to CRAN.

Make a PR that adds a `.9999` on the end of the version you just released. This is a common practice in open source software development. It makes it obvious that the code in source control is newer than what's available from package managers, but doesn't interfere with the [semantic versioning](https://semver.org/) components of the package version.
