FROM  quay.io/wtsicgp/dockstore-cgpwxs:1.0.2

MAINTAINER  keiranmraine@gmail.com

LABEL uk.ac.sanger.cgp="Cancer Genome Project, Wellcome Trust Sanger Institute" \
      version="1.0.0" \
      description="The CGP WGS pipeline for dockstore.org"

USER  root

ENV OPT /opt/wtsi-cgp
ENV PATH $OPT/bin:$PATH
ENV PERL5LIB $OPT/lib/perl5
ENV R_LIBS $OPT/R-lib
ENV R_LIBS_USER $R_LIBS

COPY build/apt-build.sh build/
RUN bash build/apt-build.sh

COPY build/perllib-build.sh build/
RUN bash build/perllib-build.sh

COPY build/opt-build.sh build/
RUN bash build/opt-build.sh

COPY scripts/analysisWGS.sh $OPT/bin/analysisWGS.sh
COPY scripts/ds-wrapper.pl $OPT/bin/ds-wrapper.pl
COPY bin/ssearch36-fasta-36.3.8d-linux64 $OPT/bin/ssearch36
RUN chmod a+x $OPT/bin/analysisWGS.sh $OPT/bin/ds-wrapper.pl $OPT/bin/ssearch36

USER    ubuntu
WORKDIR /home/ubuntu

CMD ["/bin/bash"]
