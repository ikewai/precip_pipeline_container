#Script for Data Processing Pipeline

## (Proposed) Get latest version of processing scripts
# Needs public final versions of the scripts:
# cd <folder for scripts>
# wget <URL of first script to grab> ... <URL of last script to grab>


## Script Execution

# HADS
r hads_24hr_webscape_5am_FINAL.R # may need additional arguments/setup

# Aggregation
r scan_daily_hourly_data_agg_FINAL.R # same as hads portion
