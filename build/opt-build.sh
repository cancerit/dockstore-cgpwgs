#!/bin/bash

set -uxe

mkdir -p /tmp/downloads

cd /tmp/downloads

# alleleCount
curl -sSL -o distro.zip --retry 10 https://github.com/cancerit/alleleCount/archive/v3.2.1.zip
mkdir /tmp/downloads/distro
bsdtar -C /tmp/downloads/distro --strip-components 1 -xf distro.zip
cd /tmp/downloads/distro
./setup.sh $OPT
cd /tmp/downloads
rm -rf distro.zip /tmp/downloads/distro /tmp/hts_cache

# cgpNgsQc
curl -sSL -o distro.zip --retry 10 https://github.com/cancerit/cgpNgsQc/archive/v1.3.0.zip
mkdir /tmp/downloads/distro
bsdtar -C /tmp/downloads/distro --strip-components 1 -xf distro.zip
cd /tmp/downloads/distro
./setup.sh $OPT
cd /tmp/downloads
rm -rf distro.zip /tmp/downloads/distro /tmp/hts_cache

# ascatNgs
curl -sSL -o distro.zip --retry 10 https://github.com/cancerit/ascatNgs/archive/v4.0.0.zip
mkdir /tmp/downloads/distro
bsdtar -C /tmp/downloads/distro --strip-components 1 -xf distro.zip
cd /tmp/downloads/distro
./setup.sh $OPT
cd /tmp/downloads
rm -rf distro.zip /tmp/downloads/distro /tmp/hts_cache

# Grass
curl -sSL -o distro.zip --retry 10 https://github.com/cancerit/grass/archive/v2.1.0.zip
mkdir /tmp/downloads/distro
bsdtar -C /tmp/downloads/distro --strip-components 1 -xf distro.zip
cd /tmp/downloads/distro
./setup.sh $OPT
cd /tmp/downloads
rm -rf distro.zip /tmp/downloads/distro /tmp/hts_cache

# BRASS
curl -sSL -o distro.zip --retry 10 https://github.com/cancerit/BRASS/archive/v5.1.6.zip
mkdir /tmp/downloads/distro
bsdtar -C /tmp/downloads/distro --strip-components 1 -xf distro.zip
cd /tmp/downloads/distro
./setup.sh $OPT
cd /tmp/downloads
rm -rf distro.zip /tmp/downloads/distro /tmp/hts_cache

# cgpBattenberg
curl -sSL -o distro.zip --retry 10 https://github.com/cancerit/cgpBattenberg/archive/1.5.1.zip
mkdir /tmp/downloads/distro
bsdtar -C /tmp/downloads/distro --strip-components 1 -xf distro.zip
cd /tmp/downloads/distro
./setup.sh $OPT
cd /tmp/downloads
rm -rf distro.zip /tmp/downloads/distro /tmp/hts_cache

rm -rf /tmp/downloads
