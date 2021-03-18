FROM ikewai/rainfallbase

# Main working directory of the container
WORKDIR /usr/src/app

# Copy operational scripts
COPY pipeline.sh /usr/src/app/pipeline.sh
COPY uploader.py /usr/src/app/uploader.py

# Get latest versions of data processing scripts
RUN mkdir /usr/src/app/scripts

COPY ../final_scripts/* /usr/src/app/scripts/.

# Allow read-write-execute to operational directories,
# to allow any user of the container to do what it needs.
RUN chmod -R 777 /usr/src/app

# Start pipeline script when container is launched
CMD ["bash", "pipeline.sh"]