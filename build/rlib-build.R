instLib = commandArgs(T)[1]

r = getOption("repos") # hard code the UK repo for CRAN
r["CRAN"] = "http://cran.uk.r-project.org"
options(repos = r)
rm(r)
source("http://bioconductor.org/biocLite.R")

ipak <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    biocLite(new.pkg, ask=FALSE, lib=instLib, lib.loc=instLib)
  sapply(pkg, library, character.only = TRUE)
}

tmp <- c("devtools")
ipak(tmp)
library(devtools)
options(download.file.method = "auto")

# ASCAT and BRASS
biocPackages <- c("data.table", "mgcv", "gam", "VGAM", "stringr", "poweRlaw", "zlibbioc", "RColorBrewer")
ipak(biocPackages)

# add for BB
biocPackages <- c("stringi", "readr", "doParallel", "ggplot2", "gridExtra", "gtools")
ipak(biocPackages)

install_github("sb43/copynumber", ref="f1688edc154f1a0e3aacf7781090afe02882f623")
