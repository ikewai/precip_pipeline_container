#Script for Data Processing Pipeline

## Script Execution

# Testing
echo "The current time is: " `date` > /usr/src/app/testing.log

# HADS
#r hads_24hr_webscape_5am_FINAL.R # may need additional arguments/setup

# Aggregation
#r scan_daily_hourly_data_agg_FINAL.R # same as hads portion


exit 0
EOF
