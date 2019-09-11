# CRAN Submission History

## v0.0.2 - Submission 1 - (July 17, 2017)

### Test environments
* Alpine 3.5 (on Jenkins CI), R 3.4.0
* local CentOS 7.3, R 3.4.0
* local OS X, R 3.3.2
* local Windows 10, R 3.3.2
* Windows via `devtools::build_win()`

### `R CMD check` results
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

### `R CMD check` results
* No issues

### CRAN Response
* Need to use CRAN canonical form (http://cran.r-project.org/package=uptasticsearch)

## v0.1.0 - Submission 2 - (August 28, 2017)

### `R CMD check` results
* No issues

### CRAN Response
* CRAN canonical form uses HTTPS (https://cran.r-project.org/package=uptasticsearch)

## v0.1.0 - Submission 3 - (August 29, 2017)

### `R CMD check` results
* No issues

### CRAN Response
* CRAN URLs are still missing HTTPS (submitter error)

## v0.1.0 - Submission 4 - (August 29, 2017)

### `R CMD check` results
* No issues

### CRAN Response
* Still missing HTTPS in CRAN URLs (we'd been editing the README at the repo root, not the one built with the package)
* Reviewers asked if examples in "\dontrun" could be run instead

## v0.1.0 - Submission 5 - (August 29, 2017)

### `R CMD check` results
* No issues

### CRAN Response
* No lingering issues. v0.1.0 released to CRAN!

## v0.2.0 - Submission 1 - (April 12, 2018)

### `R CMD check` results
* No issues

### CRAN Response
* No issues. v0.2.0 released to CRAN!

## v0.3.0 - Submission 1 - (June 18, 2018)

### `R CMD check` results
* No issues

### CRAN Response
* No issues. v0.3.0 released to CRAN!

## v0.3.1 - Submission 1 - (January 28, 2019)

### `R CMD check` results
* Issues on several platforms, of the form `premature EOF...`. This is a result of forgetting to put the test data in the package tarball before upload.

### CRAN Response
* Upload a new version with this fixed or your package comes down in 7 days

## v0.3.1 - Submission 2 - (January 29, 2019)

### `R CMD check` results
* Empty links in `NEWS.md`

### CRAN Response
* Upload a new version with this fixed or your package comes down in 7 days

## v0.3.1 - Submission 3 - (January 30, 2019)

### `R CMD check` results
* No issues

### CRAN Response
* No issues. v0.3.1 released to CRAN!

## v0.4.0 - Submission 1 - (September 9, 2019)

In this submission, we changed maintainer from `james.lamb@uptake.com` to `jaylamb20@gmail.com`. Added this note in the initial submission:

> This is a release to add support for Elasticsearch 7.x, a major release stream that has been General Availability since April 2019.

> You may see that the maintainer email is changing from "james.lamb@uptake.com" to "jaylamb20@gmail.com". This is a contact info update only, not an actual maintainer change. The "uptake.com" address is tied to the company that holds copyright over this project (https://github.com/uptake/uptasticsearch/blob/master/LICENSE#L3). I no longer work there but have received their permission to continue on as the maintainer. If you need confirmation you can contact my coauthors who still work there (austin.dickey@uptake.com, nick.paras@uptake.com) or that company's legal team (dennis.lee@uptake.com) 

### `R CMD check` results
* No issues

### CRAN Response
* Release was auto-accepted, but the response email said "We are waiting for confirmation from the old maintainer address now.". I responded and re-iterated the message above about changed maintainer email. No response yet. We are blocked until they respond.
* CRAN seems ok with the maintainer change, noted that we have one bad link in `README.md`, "`./CONTRIBUTING.md"`. Needs to be changed to a fully-specified URL.

## v0.4.0 - Submission 1 - (September 11, 2019)

### `R CMD check` results
* No isses

### CRAN Response
* TBD
