#!/bin/bash

set -eux

apt-get update
apt-get install -qy --no-install-recommends gfortran
#apt-get install -qy --no-install-recommends r-base r-base-dev
