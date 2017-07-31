FROM  quay.io/wtsicgp/dockstore-cgpwxs:2.1.1

MAINTAINER  keiranmraine@gmail.com

LABEL uk.ac.sanger.cgp="Cancer Genome Project, Wellcome Trust Sanger Institute" \
      version="1.1.0" \
      description="The CGP WGS pipeline for dockstore.org"

USER  root

ENV OPT /opt/wtsi-cgp
ENV PATH $OPT/bin:$PATH
ENV PERL5LIB $OPT/lib/perl5
ENV LD_LIBRARY_PATH $OPT/lib
ENV R_LIBS $OPT/R-lib
ENV R_LIBS_USER $R_LIBS

COPY build/apt-build.sh build/
RUN bash build/apt-build.sh

COPY build/rlib-build.R build/
RUN mkdir -p $R_LIBS_USER && Rscript build/rlib-build.R $R_LIBS_USER

COPY build/perllib-build.sh build/
RUN bash build/perllib-build.sh

COPY build/opt-build.sh build/
RUN bash build/opt-build.sh $OPT

COPY scripts/analysisWGS.sh $OPT/bin/analysisWGS.sh
COPY scripts/ds-wrapper.pl $OPT/bin/ds-wrapper.pl
RUN chmod a+x $OPT/bin/analysisWGS.sh $OPT/bin/ds-wrapper.pl

### security upgrades and cleanup
RUN apt-get -yq update && \
    apt-get -yq install unattended-upgrades && \
    unattended-upgrades

USER    ubuntu
WORKDIR /home/ubuntu

CMD ["/bin/bash"]
