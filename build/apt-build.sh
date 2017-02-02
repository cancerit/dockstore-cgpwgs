#!/bin/bash

set -eux

apt-get -yq update
apt-get -yq install gfortran
apt-get -yq install r-base r-base-dev

### security upgrades and cleanup
apt-get -yq install unattended-upgrades
unattended-upgrades
apt -yq autoremove
apt-get clean
