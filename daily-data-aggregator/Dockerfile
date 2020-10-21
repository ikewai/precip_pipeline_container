FROM ikewai/rainfallbase

WORKDIR /usr/src/app

COPY pipeline.sh /usr/src/app/pipeline.sh
COPY uploader.py /usr/src/app/uploader.py

## Container Setup 

# Install Git, to grab the scripts
RUN apt install git

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
# Future: These scripts will come from the 'rainfallscripts' repo, once it's ready.
RUN git clone https://github.com/ikewai/precip_pipeline_container.git /usr/src/app/repo

RUN cp /usr/src/app/repo/final_scripts/* /usr/src/app/scripts/.

# Set user to abaco, chmod everything in /usr/src/app 777, recursively
RUN useradd -ms /bin/bash abaco
RUN chown abaco /usr/src/app -R
USER abaco

CMD ["bash", "pipeline.sh"]