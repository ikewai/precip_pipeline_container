echo "Grabbing prerequisites."

### Get necessary APT-type packages

# First, get APT ready
rm /etc/apt/apt.conf.d/default
echo "//APT::Default-Release \"testing\";" > /etc/apt/apt.conf.d/default
apt update

# Next, get non-R dependencies
apt install nano -y                     # preference
apt install libxml2-dev -y              # RNRCS
apt install libssl-dev -y               # openssl
apt install curl -y                     # Rcurl
apt install libcurl4-openssl-dev -y     # Rcurl

### Get necessary R-type packages
r rainfall-prereqs.r
sleep infinity