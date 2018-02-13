FROM  quay.io/wtsicgp/dockstore-cgpwxs:3.0.0-rc2 as builder

USER  root

RUN apt-get update
RUN apt-get install -qy --no-install-recommends lsb-release

RUN echo "deb http://cran.rstudio.com/bin/linux/ubuntu `lsb_release -cs`/" >> /etc/apt/sources.list
RUN gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9
RUN gpg -a --export E084DAB9 | apt-key add -

RUN apt-get update
RUN apt-get install -qy --no-install-recommends\
  locales\
  libcurl4-openssl-dev\
  libssl-dev\
  g++\
  make\
  gcc\
  pkg-config\
  zlib1g-dev\
  libreadline6-dev\
  libcairo2-dev\
  gfortran\
  unzip\
  libboost-all-dev\
  libpstreams-dev\
  r-base\
  r-base-dev\
  libblas-dev\
  libbz2-dev

RUN locale-gen en_US.UTF-8
RUN update-locale LANG=en_US.UTF-8

ENV OPT /opt/wtsi-cgp
ENV PATH $OPT/bin:$PATH
ENV PERL5LIB $OPT/lib/perl5
ENV LD_LIBRARY_PATH $OPT/lib
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV R_LIBS $OPT/R-lib
ENV R_LIBS_USER $R_LIBS

COPY build/rlib-build.R build/
RUN mkdir -p $R_LIBS_USER && Rscript build/rlib-build.R $R_LIBS_USER

COPY build/opt-build.sh build/
RUN bash build/opt-build.sh $OPT

FROM  ubuntu:16.04

MAINTAINER  keiranmraine@gmail.com

LABEL uk.ac.sanger.cgp="Cancer Genome Project, Wellcome Trust Sanger Institute" \
      version="2.0.0-rc1" \
      description="The CGP WGS pipeline for dockstore.org"

RUN apt-get -yq update
RUN apt-get install -yq --no-install-recommends\
  apt-transport-https\
  locales\
  curl\
  ca-certificates\
  libperlio-gzip-perl\
  bzip2\
  psmisc\
  time\
  zlib1g\
  liblzma5\
  libncurses5\
  libcairo2\
  gfortran\
  libboost-all\
  libpstreams\
  r-base\
  libblas\
  exonerate

RUN locale-gen en_US.UTF-8
RUN update-locale LANG=en_US.UTF-8

ENV OPT /opt/wtsi-cgp
ENV PATH $OPT/bin:$PATH
ENV PERL5LIB $OPT/lib/perl5
ENV LD_LIBRARY_PATH $OPT/lib
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV R_LIBS $OPT/R-lib
ENV R_LIBS_USER $R_LIBS

COPY scripts/analysisWGS.sh $OPT/bin/analysisWGS.sh
COPY scripts/ds-wrapper.pl $OPT/bin/ds-wrapper.pl
RUN chmod a+x $OPT/bin/analysisWGS.sh $OPT/bin/ds-wrapper.pl

USER    ubuntu
WORKDIR /home/ubuntu

CMD ["/bin/bash"]
