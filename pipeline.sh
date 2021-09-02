#Script for Data Processing Pipeline

# NOTE: This is currently configured for offline testing.

### SETUP ###
# all_data_daily_merge_table_FINAL.R
mkdir -p \
/workflows/dailyDataGet/HADS/outFiles/agg \
/workflows/dailyDataGet/NWS/outFiles/agg \
/workflows/dailyDataGet/SCAN/outFiles/agg \
/workflows/dailyDataCombine/missing \
/workflows/dailyDataCombine/count \
/workflows/dailyDataCombine/rainfall \
/workflows/dailyDataCombine/source \

# hads_24hr_webscape_1am_FINAL.R and hads_24hr_webscape_5am_FINAL.R
mkdir -p \
/workflows/dailyDataGet/HADS/outFiles/raw \
/workflows/dailyDataGet/HADS/outFiles/parse \
/workflows/dailyDataGet/HADS/outFiles/agg \

# nws_hrly_24hr_webscape_FINAL.R
mkdir -p \
/workflows/dailyDataGet/NWS/outFiles/raw \
/workflows/dailyDataGet/NWS/outFiles/parse \
/workflows/dailyDataGet/NWS/outFiles/agg \

# scan_daily_hourly_data_agg_FINAL.R
mkdir -p \
/workflows/dailyDataGet/SCAN/outFiles/parse \
/workflows/dailyDataGet/SCAN/outFiles/agg \

# qaqc_randfor_bad_data_flag_remove.R
mkdir -p \
/workflows/dailyDataCombine/rainfall \
/workflows/dependencies/probRasters \
/workflows/dependencies/models \
/workflows/dailyQAQC/rainfall_QAQC \

# step8_randfor_find_bad_data_interation_per_FINAL.R
mkdir -p \
/workflows/qaqc/data_attribute_run/output/finalData \
/workflows/qaqc/data_attribute_run/final_results/iteration_analysis \

# Set environment variables from abaco msg
# python3 /usr/src/app/set_env.py
# if [ $? -eq 1 ]; then
#     echo "There was a problem with set_env. Exiting pipeline."
# # Download necessary run-time prereqs
# python3 /usr/src/app/downloader.py
# if [ $? -eq 1 ]; then
#     echo "There was a problem with downloader. Exiting pipeline."

# Download, Decompress, Place Dependency Data Files
cd /workflows/dependencies
echo "downloading dependency folder"
wget -q https://ikeauth.its.hawaii.edu/files/v2/download/publidc/system/ikewai-annotated-data/Rainfall/hcdp_dep.zip
unzip hcdp_dep.zip
mv -f HCDP_dep*s/* /workflows/dependencies/.

### END SETUP ###

### RAINFALL WORKFLOW ###

# DailyDataGet
Rscript /workflows/dailyDataGet/HADS/hads_24hr_webscape_1am_FINAL.R
Rscript /workflows/dailyDataGet/HADS/hads_24hr_webscape_5am_FINAL.R
Rscript /workflows/dailyDataGet/NWS/nws_hrly_24hr_webscape_FINAL.R
Rscript /workflows/dailyDataGet/SCAN/scan_daily_hourly_data_agg_FINAL.R

# DailyDataCombine
Rscript /workflows/dailyDataCombine/all_data_daily_merge_table_FINAL.R

# DailyQAQC
Rscript /workflows/dailyQAQC/qaqc_randfor_bad_data_flag_remove.R
Rscript /workflows/dailyQAQC/step8_randfor_find_bad_data_interation_per_FINAL.R

### END RAINFALL WORKFLOW ###

### POST-WORKFLOW OPERATIONS ###
# Upload Data/Results
# python3 /container_scripts/uploader.py
# if [ $? -eq 1 ]; then
#     echo "There was a problem with uploader."

# Run Ingestion

/bin/bash
exit 0
EOF