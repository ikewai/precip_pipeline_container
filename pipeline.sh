#Script for Data Processing Pipeline

## Script Execution
# /work is the working directory that gets mounted in the container by abaco.
#
# For reference:
# hads_final uses data/raw/hads/raw_files   ; 
#                 data/raw/hads/parsed_data ;
#                 data/raw/hads/daily_agg   ;
# 
# scan_final uses data/raw/scan/raw_parsed  ;
#                 data/raw/scan/daily_agg   ;
# THIS IS NOW OUTDATED, CHANGING WITH MERGE TO DEV
chmod -R 777 /work

cd /work
mkdir -p \
raw/hads/raw_files \
raw/hads/parsed_data \
raw/hads/daily_agg \
raw/scan/raw_parsed \
raw/scan/daily_agg 

# For initial testing: display the contents of the work folder.
ls /work

# Download necessary run-time prereqs
#python3 /usr/src/app/downloader.py

# HADS
r /usr/src/app/scripts/hads_final.r

# Aggregation
r /usr/src/app/scripts/scan_final.r

# For initial testing: display the contents of the raw_parsed folder.
ls /work/data/raw/scan/raw_parsed

# Upload Data/Results
python3 /usr/src/app/uploader.py

# Run Ingestion Flow


exit 0
EOF