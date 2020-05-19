FROM mdodgehawaii/rainfall-core:latest

WORKDIR /usr/src/app

COPY . .

## Container Setup 

# Get necessary packages
RUN apt install -y cron nano

# Set up cron
RUN touch "/var/spool/cron/crontabs/rainfall_cron"
RUN crontab "var/spool/cron/crontabs/rainfall_cron"
RUN echo "*/30 * * * * bash pipeline.sh >/dev/null 2>&1" > "/var/spool/cron/crontabs/rainfall_cron"

# (Proposed) Get latest versions of data processing scripts
#RUN mkdir scripts
#RUN wget <URL of first script>...<URL of last script> -P scripts/

CMD ["bash", "pipeline.sh"]