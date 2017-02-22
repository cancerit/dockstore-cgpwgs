#!/bin/bash

set -xe

if [[ -z "${TMPDIR}" ]]; then
  TMPDIR=/tmp
fi

set -u

### BRASS WILL NEED THIS:
# cpanm --no-interactive --notest --mirror http://cpan.metacpan.org -l $INST_PATH Bio::Tools::Run::WrapperBase

mkdir -p $TMPDIR/downloads $R_LIBS

cd $TMPDIR/downloads

# alleleCount
curl -sSL -o distro.zip --retry 10 https://github.com/cancerit/alleleCount/archive/v3.2.2.zip
mkdir $TMPDIR/downloads/distro
bsdtar -C $TMPDIR/downloads/distro --strip-components 1 -xf distro.zip
cd $TMPDIR/downloads/distro
./setup.sh $OPT
cd $TMPDIR/downloads
rm -rf distro.zip $TMPDIR/downloads/distro /tmp/hts_cache

# cgpNgsQc
curl -sSL -o distro.zip --retry 10 https://github.com/cancerit/cgpNgsQc/archive/v1.3.0.zip
mkdir $TMPDIR/downloads/distro
bsdtar -C $TMPDIR/downloads/distro --strip-components 1 -xf distro.zip
cd $TMPDIR/downloads/distro
./setup.sh $OPT
cd $TMPDIR/downloads
rm -rf distro.zip $TMPDIR/downloads/distro /tmp/hts_cache

# ascatNgs
curl -sSL -o distro.zip --retry 10 https://github.com/cancerit/ascatNgs/archive/v4.0.0.zip
mkdir $TMPDIR/downloads/distro
bsdtar -C $TMPDIR/downloads/distro --strip-components 1 -xf distro.zip
cd $TMPDIR/downloads/distro
./setup.sh $OPT
cd $TMPDIR/downloads
rm -rf distro.zip $TMPDIR/downloads/distro /tmp/hts_cache

# Grass
curl -sSL -o distro.zip --retry 10 https://github.com/cancerit/grass/archive/v2.1.0.zip
mkdir $TMPDIR/downloads/distro
bsdtar -C $TMPDIR/downloads/distro --strip-components 1 -xf distro.zip
cd $TMPDIR/downloads/distro
./setup.sh $OPT
cd $TMPDIR/downloads
rm -rf distro.zip $TMPDIR/downloads/distro /tmp/hts_cache

# BRASS and RSupport
curl -sSL -o distro.zip --retry 10 https://github.com/cancerit/BRASS/archive/v5.2.0.zip
mkdir $TMPDIR/downloads/distro
bsdtar -C $TMPDIR/downloads/distro --strip-components 1 -xf distro.zip
cd $TMPDIR/downloads/distro/Rsupport
Rscript libInstall.R $R_LIBS
cd $TMPDIR/downloads/distro
./setup.sh $OPT
cd $TMPDIR/downloads
rm -rf distro.zip $TMPDIR/downloads/distro /tmp/hts_cache

# cgpBattenberg
curl -sSL -o distro.zip --retry 10 https://github.com/cancerit/cgpBattenberg/archive/release/2.0.0.zip
mkdir $TMPDIR/downloads/distro
bsdtar -C $TMPDIR/downloads/distro --strip-components 1 -xf distro.zip
cd $TMPDIR/downloads/distro
./setup.sh $OPT
cd $TMPDIR/downloads
rm -rf distro.zip $TMPDIR/downloads/distro /tmp/hts_cache

rm -rf $TMPDIR/downloads
