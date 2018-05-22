FROM r-base:latest
MAINTAINER jaylamb20@gmail.com

ADD . /code

WORKDIR /code

RUN Rscript -e "install.packages('devtools', repos='http://cran.rstudio.com')" && \
    Rscript -e "devtools::install()"

CMD ["Rscript -e 'devtools::test()'"]
