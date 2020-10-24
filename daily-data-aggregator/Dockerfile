FROM ikewai/rainfallbase

WORKDIR /usr/src/app

COPY pipeline.sh /usr/src/app/pipeline.sh
COPY uploader.py /usr/src/app/uploader.py


## Container Setup 

# Install Git, to grab the scripts, and Python, to execute them.
# Tapipy may be needed for using the uploader script, once it is written.
RUN apt install git python3 python3-pip -y
RUN pip3 install tapipy

# Get latest versions of data processing scripts
# Future: These scripts will come from the 'rainfallscripts' repo, once it's ready.
RUN git clone https://github.com/ikewai/precip_pipeline_container.git /usr/src/app/repo

RUN mkdir /usr/src/app/scripts

RUN cp /usr/src/app/repo/final_scripts/* /usr/src/app/scripts/.

# chmod everything in /usr/src/app 777, recursively
RUN chmod -R 777 /usr/src/app

CMD ["bash", "pipeline.sh"]