#DEPRECATED, COMMANDS MOVED TO DOCKERFILE.

# First, get APT ready
rm /etc/apt/apt.conf.d/default
echo "//APT::Default-Release \"testing\";" > /etc/apt/apt.conf.d/default
apt update

# dependencies for R packages
R_deps="libxml2-dev libssl-dev curl libcurl4-openssl-dev"
# for RNRCS, openssl, RCurl, RCurl respectively.
apt install $R_deps -y

# dependencies for container operations
OP_deps="nano cron"
apt install $OP_deps -y