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

# Get latest versions of data processing scripts OR
# Alternative would be supplying the scripts at runtime.
#RUN wget <URL of first script>...<URL of last script> -P scripts


CMD ["sleep", "infinity"]