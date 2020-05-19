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

CMD ["bash", "pipeline.sh"]