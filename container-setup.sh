echo "Grabbing prerequisites."

### Get necessary APT-type packages

# First, get APT ready
rm /etc/apt/apt.conf.d/default
echo "//APT::Default-Release \"testing\";" > /etc/apt/apt.conf.d/default
apt update

# Next, get packages
apt install nano # personal preference for CLI text editor
apt install libxml2-dev # necessary for R package RNRCS


### Get necessary R-type packages
r rainfall-prereqs.r
sleep infinity