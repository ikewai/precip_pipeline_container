FROM debian:stable

RUN apt update

# OS dependencies for R packages
RUN apt install -y r-base libxml2-dev libssl-dev curl libcurl4-openssl-dev
# for R, RNRCS, openssl, RCurl, RCurl respectively.

# R dependencies for rainfall scripts
RUN R -e 'install.packages(c("ggplot2","xts","RNRCS","metScanR","lubridate"))'