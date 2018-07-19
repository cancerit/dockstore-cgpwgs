FROM  quay.io/wtsicgp/dockstore-cgpwgs:1.1.2

MAINTAINER  keiranmraine@gmail.com

LABEL uk.ac.sanger.cgp="Cancer Genome Project, Wellcome Trust Sanger Institute" \
      version="1.1.4" \
      description="The CGP WGS pipeline for dockstore.org"

USER  root

ENV OPT /opt/wtsi-cgp
ENV PATH $OPT/bin:$PATH
ENV PERL5LIB $OPT/lib/perl5
ENV LD_LIBRARY_PATH $OPT/lib
ENV R_LIBS $OPT/R-lib
ENV R_LIBS_USER $R_LIBS

COPY scripts/analysisWGS.sh $OPT/bin/analysisWGS.sh
COPY scripts/ds-wrapper.pl $OPT/bin/ds-wrapper.pl
RUN chmod a+x $OPT/bin/analysisWGS.sh $OPT/bin/ds-wrapper.pl

USER    ubuntu
WORKDIR /home/ubuntu

CMD ["/bin/bash"]
