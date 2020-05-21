FROM mdodgehawaii/rainfall-core:latest

WORKDIR /usr/src/app

COPY . .

## Container Setup 

# Get necessary packages
RUN apt install -y cron nano

# Set up cron
RUN touch "/var/spool/cron/crontabs/rainfall_cron"
RUN echo "* * * * * /bin/bash /usr/src/app/pipeline.sh > /usr/src/app/pipeline.log" > "/var/spool/cron/crontabs/rainfall_cron"
RUN crontab -u root "/var/spool/cron/crontabs/rainfall_cron"

# (Proposed) Get latest versions of data processing scripts
#RUN mkdir scripts
#RUN wget <URL of first script>...<URL of last script> -P scripts/

CMD ["sleep", "infinity"]