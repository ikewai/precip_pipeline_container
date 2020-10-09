FROM r-base:latest

WORKDIR /usr/src/app

COPY . .

## Dependencies

# Fix r-base's apt shenanigans
RUN rm /etc/apt/apt.conf.d/default
RUN apt update

# OS dependencies for R packages
RUN apt install -y libxml2-dev libssl-dev curl libcurl4-openssl-dev
# for RNRCS, openssl, RCurl, RCurl respectively.

# R dependencies for rainfall scripts
RUN r -e 'install.packages(c("ggplot2","xts","RNRCS","metScanR","lubridate"))'