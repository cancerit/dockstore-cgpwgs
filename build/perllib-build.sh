#!/bin/bash

set -eux

apt-get -yq update
# install all perl libs, identify by grep of build "grep 'Successfully installed' build.log"
# much faster, items needing later versions will still upgrade
# still install those that get an upgrade though as dependancies will be resolved

#apt-get -yq install ...
