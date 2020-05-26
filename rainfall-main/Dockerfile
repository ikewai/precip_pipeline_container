FROM mdodgehawaii/rainfall-core:latest

WORKDIR /usr/src/app

COPY . .

## Container Setup 

# for testing
RUN apt install -y nano 

## Create directories for scripts, intermediate data, etc
# For reference:
# hads_final uses data/raw/hads/raw_files   , 
#                 data/raw/hads/parsed_data ,
#                 data/raw/hads/daily_agg   ;
# 
# scan_final uses data/raw/scan/raw_parsed  ,
#                 data/raw/scan/daily_agg   ;

RUN mkdir -p scripts \
data/raw/hads/raw_files \
data/raw/hads/parsed_data \
data/raw/hads/daily_agg \
data/raw/scan/raw_parsed \
data/raw/scan/daily_agg 

# Get latest versions of data processing scripts
# Future: These scripts will come from a dedicated repo, and Docker will be 
#  set up such that a fresh build will be generated whenever either repo is modified.
RUN wget \
https://raw.githubusercontent.com/ikewai/precip_pipeline_container/master/final_scripts/hads_final.r \
https://raw.githubusercontent.com/ikewai/precip_pipeline_container/master/final_scripts/scan_final.r \
-P scripts


CMD ["sleep", "infinity"]