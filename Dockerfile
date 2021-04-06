FROM ikewai/rainfallbase

# Main working directory of the container
WORKDIR /usr/src/app

# Copy operational scripts
COPY pipeline.sh /usr/src/app/pipeline.sh
COPY gateway_scripts/uploader.py /usr/src/app/.
COPY gateway_scripts/downloader.py /usr/src/app/.

# Copy acquisition/aggregation scripts
RUN mkdir /usr/src/app/scripts
COPY final_scripts/* /usr/src/app/scripts/

# Allow read-write-execute to operational directories,
# to allow any user of the container to do what it needs.
RUN chmod -R 777 /usr/src/app

# Start pipeline script when container is launched
CMD ["bash", "pipeline.sh"]