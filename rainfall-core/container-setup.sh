echo "Grabbing prerequisites."

### Get necessary APT-type packages

# First, get APT ready
rm /etc/apt/apt.conf.d/default
echo "//APT::Default-Release \"testing\";" > /etc/apt/apt.conf.d/default
apt update

# Next, get non-R dependencies
apt install nano -y         # personal preference for CLI text editor
apt install libxml2-dev -y  # necessary for R package RNRCS
apt install libssl-dev -y   # necessary for R package openssl
apt install curl -y         # necessary for R package Rcurl

### Get necessary R-type packages
r rainfall-prereqs.r
sleep infinity