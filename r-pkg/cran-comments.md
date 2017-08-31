# CRAN Submission History

## v0.0.2 - Submission 1 - (July 17, 2017)

### Test environments
* Alpine 3.5 (on Jenkins CI), R 3.4.0
* local CentOS 7.3, R 3.4.0
* local OS X, R 3.3.2
* local Windows 10, R 3.3.2
* Windows via `devtools::build_win()`

### R CMD check results
* There were no ERRORs, WARNINGs.  
* One NOTE from `checking CRAN incoming feasibility ...` can be safely ignored since it's a note that notifies CRAN that this is a new maintainer/submission. 

### CRAN Response
* Automatic checking upon CRAN submission yielded two notes. One was the "incoming feasbility..." item we mentioned above, which is not an issue. 
* The other note said that `Author field differs from that derived from Authors@R`. This did not arise when running `R CMD check --as-cran` locally, but it looks like "fnd" is not a supported tag for an author. Removed that tag.

## v0.0.2 - Submission 2 - (July 17, 2017)

### CRAN Response
* Need to use the [CRAN preferred method](https://cran.r-project.org/web/licenses/BSD_3_clause) of declaring the BSD 3-Clause license
* Need to quote software names

## v0.0.2 - Submission 3 - (July 18, 2017)

### CRAN Response
* No lingering issues. v0.0.2 released to CRAN!

## v0.1.0 - Submission 1 - (August 28, 2017)

### R CMD check results
* No issues

### CRAN Response
* Need to use CRAN canonical form (http://cran.r-project.org/package=uptasticsearch)

## v0.1.0 - Submission 2 - (August 28, 2017)

### R CMD check results
* No issues

### CRAN Response
* CRAN canonical form uses HTTPS (https://cran.r-project.org/package=uptasticsearch)

## v0.1.0 - Submission 3 - (August 29, 2017)

### R CMD check results
* No issues

### CRAN Response
* CRAN URLs are still missing HTTPS (submitter error)

## v0.1.0 - Submission 4 - (August 29, 2017)

### R CMD check results
* No issues

### CRAN Response
* Still missing HTTPS in CRAN URLs (we'd been editing the README at the repo root, not the one built with the package)
* Reviewers asked if examples in "\dontrun" could be run instead

## v0.1.0 - Submission 5 - (August 29, 2017)

### R CMD check results
* No issues

### CRAN Response
* No lingering issues. v0.0.2 released to CRAN!

