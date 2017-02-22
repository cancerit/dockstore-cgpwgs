#!/bin/bash

set -xe

if [[ -z "${TMPDIR}" ]]; then
  TMPDIR=/tmp
fi

set -u

VER_ALLELECOUNT="v3.2.3"



if [ "$#" -lt "1" ] ; then
  echo "Please provide an installation path such as /opt/ICGC"
  exit 1
fi

# get path to this script
SCRIPT_PATH=`dirname $0`;
SCRIPT_PATH=`(cd $SCRIPT_PATH && pwd)`

# get the location to install to
INST_PATH=$1
mkdir -p $1
INST_PATH=`(cd $1 && pwd)`
echo $INST_PATH

# get current directory
INIT_DIR=`pwd`

CPU=`grep -c ^processor /proc/cpuinfo`
if [ $? -eq 0 ]; then
  if [ "$CPU" -gt "6" ]; then
    CPU=6
  fi
else
  CPU=1
fi
echo "Max compilation CPUs set to $CPU"

SETUP_DIR=$INIT_DIR/install_tmp
mkdir -p $SETUP_DIR/distro # don't delete the actual distro directory until the very end
mkdir -p $INST_PATH/bin
cd $SETUP_DIR

# make sure tools installed can see the install loc of libraries
set +u
export LD_LIBRARY_PATH=`echo $INST_PATH/lib:$LD_LIBRARY_PATH | perl -pe 's/:\$//;'`
export PATH=`echo $INST_PATH/bin:$PATH | perl -pe 's/:\$//;'`
export MANPATH=`echo $INST_PATH/man:$INST_PATH/share/man:$MANPATH | perl -pe 's/:\$//;'`
export PERL5LIB=`echo $INST_PATH/lib/perl5:$PERL5LIB | perl -pe 's/:\$//;'`
set -u

##### alleleCount installation
if [ ! -e $SETUP_DIR/alleleCount.success ]; then
  curl -sSL --retry 10 https://github.com/cancerit/alleleCount/archive/${VER_ALLELECOUNT}.tar.gz > distro.tar.gz
  rm -rf distro/*
  tar --strip-components 1 -C distro -xzf distro.tar.gz
  cd distro
  if [ ! -e $SETUP_DIR/alleleCount_c.success ]; then
    make -C c clean
    make -C c -j$CPU prefix=$INST_PATH HTSLIB=$INST_PATH/lib
    cp c/bin/alleleCounter $INST_PATH/bin/.
    touch $SETUP_DIR/alleleCount_c.success
  fi
  cd perl
  cpanm --no-interactive --notest --mirror http://cpan.metacpan.org --notest -l $INST_PATH --installdeps .
  cpanm -v --no-interactive --mirror http://cpan.metacpan.org -l $INST_PATH .
  cd $SETUP_DIR
  rm -rf distro.* distro/*
  touch $SETUP_DIR/alleleCount.success
fi

exit 0

### BRASS WILL NEED THIS:
# cpanm --no-interactive --notest --mirror http://cpan.metacpan.org -l $INST_PATH Bio::Tools::Run::WrapperBase

mkdir -p $TMPDIR/downloads $R_LIBS

cd $TMPDIR/downloads

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
