FROM ikewai/rainfallbase

# Main working directory of the container
WORKDIR /container_scripts

# Copy operational scripts
COPY pipeline.sh .
COPY gateway_scripts/uploader.py .
COPY gateway_scripts/downloader.py .
COPY gateway_scripts/set_env.py .
COPY gateway_scripts/offline_testing.py .

# Copy acquisition/aggregation scripts
WORKDIR /workflows
RUN mkdir -p dailyDataCombine dailyDataGet/HADS dailyDataGet/NWS dailyDataGet/SCAN dailyQAQC
COPY final_scripts/workflows/dailyDataCombine /workflows/dailyDataCombine/.
COPY final_scripts/workflows/dailyDataGet/HADS/* /workflows/dailyDataGet/HADS/.
COPY final_scripts/workflows/dailyDataGet/NWS/* /workflows/dailyDataGet/NWS/.
COPY final_scripts/workflows/dailyDataGet/SCAN/* /workflows/dailyDataGet/SCAN/.
COPY final_scripts/workflows/dailyQAQC/* /workflows/dailyQAQC/.

# Allow read-write-execute to operational directories,
# to allow any user of the container to do what it needs.
RUN chmod -R 777 /workflows
RUN chmod -R 777 /container_scripts

# Start pipeline script when container is launched
CMD ["bash", "/container_scripts/pipeline.sh"]