#!/bin/bash

set -eux

apt-get update
apt-get install -qy --no-install-recommends libreadline6-dev
apt-get install -qy --no-install-recommends libcairo2-dev
apt-get install -qy --no-install-recommends gfortran
