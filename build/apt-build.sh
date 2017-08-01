#!/bin/bash

set -eux

UBUNTU_VER=`lsb_release -cs`

echo "deb http://cran.rstudio.com/bin/linux/ubuntu $UBUNTU_VER/" >> /etc/apt/sources.list
gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9
gpg -a --export E084DAB9 | apt-key add -

apt-get update
apt-get install -qy --no-install-recommends libreadline6-dev
apt-get install -qy --no-install-recommends libcairo2-dev
apt-get install -qy --no-install-recommends gfortran
apt-get install -qy --no-install-recommends unzip
apt-get install -qy --no-install-recommends libboost-all-dev
apt-get install -qy --no-install-recommends libpstreams-dev
apt-get install -qy --no-install-recommends r-base
apt-get install -qy --no-install-recommends libblas-dev
