#!/bin/bash

set -xe

if [[ -z "${TMPDIR}" ]]; then
  TMPDIR=/tmp
fi

set -u

### alleleCount
VER_ALLELECOUNT="v3.2.3"

### cgpNgsQc
VER_CGPNGSQC="v1.4.0"
VER_VERIFYBAM="1.1.2"

### ascatNgs
VER_ASCATNGS="v4.0.0"
SRC_ASCAT="https://raw.githubusercontent.com/Crick-CancerGenomics/ascat/6d40e69a2919ddfc1cda870310203c772bf846ce/ASCAT/R/ascat.R"

### grass
VER_GRASS="v2.1.0"

### BRASS
VER_BRASS="feature/switchToCgpBigWig" #"v5.2.0"
SOURCE_BLAT="http://users.soe.ucsc.edu/~kent/src/blatSrc35.zip"
SRC_FASTA36="https://github.com/wrpearson/fasta36/archive/v36.3.8d_13Apr16.tar.gz"
# Warning bedtools 2.24.0 and 2.25.0 have a swapped usage in coverageBed
# No upgrades until [this ticket](https://github.com/arq5x/bedtools2/issues/319) is resolved
VER_BEDTOOLS="2.21.0" # leading 'v' intentionally left off

### cgpBattenberg
VER_CGPBB="release/2.0.0"


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

### cgpNgsQc
if [ ! -e $SETUP_DIR/cgpNgsQc.success ]; then

  curl -sSL https://github.com/statgen/verifyBamID/releases/download/v${VER_VERIFYBAM}/verifyBamID.${VER_VERIFYBAM} > $OPT/bin/verifyBamId
  chmod +x $OPT/bin/verifyBamId

  curl -sSL --retry 10 https://github.com/cancerit/cgpNgsQc/archive/${VER_CGPNGSQC}.tar.gz > distro.tar.gz
  rm -rf distro/*
  tar --strip-components 1 -C distro -xzf distro.tar.gz
  cd distro
  cpanm --no-interactive --notest --mirror http://cpan.metacpan.org --notest -l $INST_PATH --installdeps .
  cpanm -v --no-interactive --mirror http://cpan.metacpan.org -l $INST_PATH .
  cd $SETUP_DIR
  rm -rf distro.* distro/*
  touch $SETUP_DIR/cgpNgsQc.success
fi

### ascatNgs
if [ ! -e $SETUP_DIR/ascatNgs.success ]; then
  curl -sSL --retry 10 https://github.com/cancerit/ascatNgs/archive/${VER_ASCATNGS}.tar.gz > distro.tar.gz
  rm -rf distro/*
  tar --strip-components 1 -C distro -xzf distro.tar.gz
  cd distro/perl

  # add ascatSrc
  curl -sSL $SRC_ASCAT > share/ascat/ascat.R

  cpanm --no-interactive --notest --mirror http://cpan.metacpan.org --notest -l $INST_PATH --installdeps .
  cpanm -v --no-interactive --mirror http://cpan.metacpan.org -l $INST_PATH .
  cd $SETUP_DIR
  rm -rf distro.* distro/*
  touch $SETUP_DIR/ascatNgs.success
fi

### grass
if [ ! -e $SETUP_DIR/grass.success ]; then
  curl -sSL --retry 10 https://github.com/cancerit/grass/archive/${VER_GRASS}.tar.gz > distro.tar.gz
  rm -rf distro/*
  tar --strip-components 1 -C distro -xzf distro.tar.gz
  cd distro

  cpanm --no-interactive --notest --mirror http://cpan.metacpan.org --notest -l $INST_PATH --installdeps .
  cpanm -v --no-interactive --mirror http://cpan.metacpan.org -l $INST_PATH .
  cd $SETUP_DIR
  rm -rf distro.* distro/*
  touch $SETUP_DIR/grass.success
fi

### BRASS
if [ ! -e $SETUP_DIR/BRASS.success ]; then

  if [ ! -e $SETUP_DIR/fasta36.success ]; then
    curl -sSL --retry 10 $SRC_FASTA36 > distro.tar.gz
    rm -rf distro/*
    tar --strip-components 1 -C distro -xzf distro.tar.gz
    cd distro/src
    make -j$CPU -f ../make/Makefile.linux64
    cp ../bin/ssearch36 $OPT/bin/.
    cd $SETUP_DIR
    rm -rf distro.* distro/*
    touch $SETUP_DIR/fasta36.success
  fi

  if [ ! -e $SETUP_DIR/bedtools.success ]; then
    curl -sSL --retry 10 https://github.com/arq5x/bedtools2/releases/download/v${VER_BEDTOOLS}/bedtools-${VER_BEDTOOLS}.tar.gz > distro.tar.gz
    rm -rf distro/*
    tar --strip-components 1 -C distro -xzf distro.tar.gz
    cd distro
    make -C distro -j$CPU
    cp distro/bin/* $INST_PATH/bin/.
    cd $SETUP_DIR
    rm -rf distro.* distro/*
    touch $SETUP_DIR/bedtools.success
  fi

  if [ ! -e $SETUP_DIR/blat.success ]; then
    curl -sSL --retry 10 $SOURCE_BLAT > distro.zip
    rm -rf distro/*
    unzip -d distro distro.zip
    cd distro/blatSrc
    BINDIR=$SETUP_DIR/blat/bin
    mkdir -p $BINDIR
    export BINDIR
    export MACHTYPE
    make -j$CPU
    cp $BINDIR/blat $INST_PATH/bin/.
    cd $SETUP_DIR
    rm -rf distro.* distro/*
    touch $SETUP_DIR/blat.success
  fi

  ## need brass distro here
  curl -sSL --retry 10 https://github.com/cancerit/BRASS/archive/${VER_BRASS}.tar.gz > distro.tar.gz
  rm -rf distro/*
  tar --strip-components 1 -C distro -xzf distro.tar.gz

  if [ ! -e $SETUP_DIR/velvet.success ]; then
    cd $SETUP_DIR/distro/distros
    tar zxf velvet_1.2.10.tgz
    cd velvet_1.2.10
    make MAXKMERLENGTH=95 velveth velvetg
    mv velveth $INST_PATH/bin/velvet95h
    mv velvetg $INST_PATH/bin/velvet95g
    make clean
    make velveth velvetg   	# don't do multi-threaded make
    mv velveth $INST_PATH/bin/velvet31h
    mv velvetg $INST_PATH/bin/velvet31g
    ln -fs $INST_PATH/bin/velvet95h $INST_PATH/bin/velveth
    ln -fs $INST_PATH/bin/velvet95g $INST_PATH/bin/velvetg
    cd $SETUP_DIR/distro
    rm -rf distros/velvet_1.2.10
    touch $SETUP_DIR/velvet.success
  fi

  if [ ! -e $SETUP_DIR/exonerate.success ]; then
    cd $SETUP_DIR/distro/distros
    tar zxf exonerate-2.2.0.tar.gz
    cd exonerate-2.2.0
    cp ../patches/exonerate_pthread-asneeded.diff .
    patch -p1 < exonerate_pthread-asneeded.diff
    ./configure --prefix=$INST_PATH
    make    # don't do multi-threaded make
    make check
    make install
    cd $SETUP_DIR/distro
    rm -rf distros/exonerate-2.2.0
    touch $SETUP_DIR/exonerate.success
  fi

  cpanm --no-interactive --notest --mirror http://cpan.metacpan.org -l $INST_PATH Graph
  cpanm --no-interactive --notest --mirror http://cpan.metacpan.org -l $INST_PATH Bio::Tools::Run::WrapperBase

  if [ -e $SETUP_DIR/brass_c.success ]; then
    cd $SETUP_DIR/distro
    rm -rf cansam*
    unzip -q distros/cansam.zip
    mv cansam-master cansam
    make -j$CPU -C cansam
    make -j$CPU -C c++
    cp c++/augment-bam $INST_PATH/bin/.
    cp c++/brass-group $INST_PATH/bin/.
    cp c++/filterout-bam $INST_PATH/bin/.
    make -C c++ clean
    rm -rf cansam
    touch $SETUP_DIR/brass_c.success
  fi

  cd $SETUP_DIR/distro/perl
  cpanm --no-interactive --notest --mirror http://cpan.metacpan.org --notest -l $INST_PATH --installdeps .
  cpanm -v --no-interactive --mirror http://cpan.metacpan.org -l $INST_PATH .
  cd $SETUP_DIR
  rm -rf distro.* distro/*
  touch $SETUP_DIR/BRASS.success
fi

### cgpBattenberg
if [ ! -e $SETUP_DIR/cgpBB.success ]; then
  curl -sSL --retry 10 https://github.com/cancerit/cgpBattenberg/archive/${VER_CGPBB}.tar.gz > distro.tar.gz
  rm -rf distro/*
  tar --strip-components 1 -C distro -xzf distro.tar.gz
  cd distro/perl
  cpanm --no-interactive --notest --mirror http://cpan.metacpan.org --notest -l $INST_PATH --installdeps .
  cpanm -v --no-interactive --mirror http://cpan.metacpan.org -l $INST_PATH .
  cd $SETUP_DIR
  rm -rf distro.* distro/*
  touch $SETUP_DIR/cgpBB.success
fi

cd $HOME
rm -rf $SETUP_DIR

echo "options(bitmapType='cairo')" > /home/ubuntu/.Rprofile
chown ubuntu:ubuntu /home/ubuntu/.Rprofile

set +x

echo "
################################################################

  To use the non-central tools you need to set the following
    export LD_LIBRARY_PATH=$INST_PATH/lib:\$LD_LIBRARY_PATH
    export PATH=$INST_PATH/bin:\$PATH
    export MANPATH=$INST_PATH/man:$INST_PATH/share/man:\$MANPATH
    export PERL5LIB=$INST_PATH/lib/perl5:\$PERL5LIB

################################################################
"
