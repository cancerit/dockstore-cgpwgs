FROM  quay.io/wtsicgp/dockstore-cgpwxs:3.0.1 as builder

USER  root

RUN bash -c 'apt-get update -yq >& this.log || (cat this.log 1>&2 && exit 1)'
RUN bash -c 'apt-get install -qy --no-install-recommends lsb-release >& this.log || (cat this.log 1>&2 && exit 1)'

RUN echo "deb http://cran.rstudio.com/bin/linux/ubuntu `lsb_release -cs`/" >> /etc/apt/sources.list
RUN gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9
RUN gpg -a --export E084DAB9 | apt-key add -

RUN bash -c 'apt-get update -yq >& this.log || (cat this.log 1>&2 && exit 1)'
RUN bash -c 'apt-get install -qy --no-install-recommends\
  locales\
  libcurl4-openssl-dev\
  libssl-dev\
  libssh2-1-dev\
  libxml2-dev\
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
  libbz2-dev\
     >& this.log || (cat this.log 1>&2 && exit 1)'

RUN bash -c 'locale-gen en_US.UTF-8 >& this.log || (cat this.log 1>&2 && exit 1)'
RUN bash -c 'update-locale LANG=en_US.UTF-8 >& this.log || (cat this.log 1>&2 && exit 1)'

ENV OPT /opt/wtsi-cgp
ENV PATH $OPT/bin:$OPT/biobambam2/bin:$PATH
ENV PERL5LIB $OPT/lib/perl5
ENV LD_LIBRARY_PATH $OPT/lib
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV R_LIBS $OPT/R-lib
ENV R_LIBS_USER $R_LIBS

COPY build/rlib-build.R build/
RUN mkdir -p $R_LIBS_USER
RUN Rscript build/rlib-build.R $R_LIBS_USER 2>&1 | grep '^\*'

COPY build/opt-build.sh build/
RUN bash build/opt-build.sh $OPT

FROM  ubuntu:16.04

MAINTAINER  keiranmraine@gmail.com

LABEL vendor="Cancer Genome Project, Wellcome Trust Sanger Institute"
LABEL uk.ac.sanger.cgp.description="CGP WGS pipeline for dockstore.org"
LABEL uk.ac.sanger.cgp.version="2.0.0"

RUN bash -c 'apt-get update -yq >& this.log || (cat this.log 1>&2 && exit 1)'
RUN bash -c 'apt-get install -qy --no-install-recommends lsb-release >& this.log || (cat this.log 1>&2 && exit 1)'

RUN echo "deb http://cran.rstudio.com/bin/linux/ubuntu `lsb_release -cs`/" >> /etc/apt/sources.list
RUN gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9
RUN gpg -a --export E084DAB9 | apt-key add -

RUN bash -c 'apt-get update -yq >& this.log || (cat this.log 1>&2 && exit 1)'
RUN bash -c 'apt-get install -yq --no-install-recommends\
  apt-transport-https\
  locales\
  curl\
  ca-certificates\
  libperlio-gzip-perl\
  libssh2-1\
  bzip2\
  psmisc\
  time\
  zlib1g\
  liblzma5\
  libncurses5\
  libcairo2\
  gfortran\
  r-base\
  exonerate\
  libboost-iostreams-dev\
  p11-kit\
     >& this.log || (cat this.log 1>&2 && exit 1)'

RUN bash -c 'locale-gen en_US.UTF-8 >& this.log || (cat this.log 1>&2 && exit 1)'
RUN bash -c 'update-locale LANG=en_US.UTF-8 >& this.log || (cat this.log 1>&2 && exit 1)'

ENV OPT /opt/wtsi-cgp
ENV PATH $OPT/bin:$OPT/biobambam2/bin:$PATH
ENV PERL5LIB $OPT/lib/perl5
ENV LD_LIBRARY_PATH $OPT/lib
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV R_LIBS $OPT/R-lib
ENV R_LIBS_USER $R_LIBS

RUN mkdir -p $OPT
COPY --from=builder $OPT $OPT

COPY scripts/analysisWGS.sh $OPT/bin/analysisWGS.sh
COPY scripts/ds-cgpwgs.pl $OPT/bin/ds-cgpwgs.pl
RUN chmod a+x $OPT/bin/analysisWGS.sh $OPT/bin/ds-cgpwgs.pl

## USER CONFIGURATION
RUN adduser --disabled-password --gecos '' ubuntu && chsh -s /bin/bash && mkdir -p /home/ubuntu

USER    ubuntu
WORKDIR /home/ubuntu

CMD ["/bin/bash"]
