echo "Grabbing prerequisites."

### Get necessary APT-type packages

# First, get APT ready
rm /etc/apt/apt.conf.d/default
echo "//APT::Default-Release \"testing\";" > /etc/apt/apt.conf.d/default
apt update

# Get apt package dependencies for R packages
apt install libxml2-dev -y              # for RNRCS
apt install libssl-dev -y               # for openssl
apt install curl -y                     # for Rcurl
apt install libcurl4-openssl-dev -y     # for Rcurl

# Get packages for container operations
apt install nano -y                     # command-line text editor
apt install cron -y                     # for automated operations

### Get necessary R-type packages
r rainfall-prereqs.r

### Set up other things

# Put pipeline.sh into cron
CRON_FILE="/var/spool/cron/crontabs/rainfall_cron"
touch $CRON_FILE
crontab $CRON_FILE
echo "*/30 * * * * bash pipeline.sh >/dev/null 2>&1" > $CRON_FILE

sleep infinity