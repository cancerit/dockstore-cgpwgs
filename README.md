dockstore-cgpwgs
======
`dockstore-cgpwgs` provides a complete multi threaded WGS analysis for SNV, INDEL, SV and Copynumber variation with associated annotation of VCF files.  This has been packaged specifically for use with the [Dockstore.org](https://dockstore.org/) framework.

[![Join the chat at https://gitter.im/dockstore-cgpwgs/general](https://badges.gitter.im/dockstore-cgpwgs/general.svg)](https://gitter.im/dockstore-cgpwgs/general?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

[![Docker Repository on Quay](https://quay.io/repository/wtsicgp/dockstore-cgpwgs/status "Docker Repository on Quay")](https://quay.io/repository/wtsicgp/dockstore-cgpwgs)

[![Build Status](https://travis-ci.org/cancerit/dockstore-cgpwgs.svg?branch=master)](https://travis-ci.org/cancerit/dockstore-cgpwgs) : master  
[![Build Status](https://travis-ci.org/cancerit/dockstore-cgpwgs.svg?branch=develop)](https://travis-ci.org/cancerit/dockstore-cgpwgs) : develop

Required input files are

1. Tumour BAM file
2. Normal BAM file
3. Core reference archive (e.g. [core_ref_GRCh37d5.tar.gz](ftp://ftp.sanger.ac.uk/pub/cancer/dockstore/human/))
4. WXS reference archive (e.g. [SNV_INDEL_ref_GRCh37d5.tar.gz](ftp://ftp.sanger.ac.uk/pub/cancer/dockstore/human/))
5. WGS reference archive (e.g. [CNV_SV_ref_GRCh37d5_brass6+.tar.gz](ftp://ftp.sanger.ac.uk/pub/cancer/dockstore/human/))
6. VAGrENT (annotation) reference archive (e.g. [VAGrENT_ref_GRCh37d5_ensembl_75.tar.gz](ftp://ftp.sanger.ac.uk/pub/cancer/dockstore/human/))
7. Subclonal reference archive ([SUBCL_ref_GRCh37d5.tar.gz])(ftp://ftp.sanger.ac.uk/pub/cancer/dockstore/human/))
  * Only needed if `skipbb` is `false`

Inputs 1&2 are expected to have been mapped using [dockstore-cgpmap](https://dockstore.org/containers/quay.io/wtsicgp/dockstore-cgpmap).

The data linked in the 'examples' area is from the cell line COLO-829.

Please check the Wiki then raise an issue if you require additional information on how to generate your own reference files.  Much of this information is available on the individual algorithm wiki pages (or the subsequently linked protocols papers).

* [BRASS](https://github.com/cancerit/BRASS/wiki)
* [cgpCaVEManWrapper](https://github.com/cancerit/cgpCaVEManWrapper/wiki)
* [cgpPindel](https://github.com/cancerit/cgpPindel/wiki)
* [ascatNgs](https://github.com/cancerit/ascatNgs/wiki)
* [VAGrENT](https://github.com/cancerit/VAGrENT/wiki)

Release process
===============
This project is maintained using HubFlow.

1. Make appropriate changes
2. Bump version in `Dockerfile` and `Dockstore.cwl`
3. Push changes
4. Check state on Travis
5. Generate the release (add notes to GitHub)
6. Confirm that image has been built on [quay.io](https://quay.io/repository/wtsicgp/dockstore-cgpwgs?tab=builds)
7. Update the [dockstore](https://dockstore.org/containers/quay.io/wtsicgp/dockstore-cgpwgs) entry, see [their docs](https://dockstore.org/docs/getting-started-with-dockstore).

LICENCE
=======

Copyright (c) 2017 Genome Research Ltd.

Author: Cancer Genome Project <cgpit@sanger.ac.uk>

This file is part of dockstore-cgpwgs.

dockstore-cgpwgs is free software: you can redistribute it and/or modify it under
the terms of the GNU Affero General Public License as published by the Free
Software Foundation; either version 3 of the License, or (at your option) any
later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
details.

You should have received a copy of the GNU Affero General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.

1. The usage of a range of years within a copyright statement contained within
this distribution should be interpreted as being equivalent to a list of years
including the first and last year specified and all consecutive years between
them. For example, a copyright statement that reads ‘Copyright (c) 2005, 2007-
2009, 2011-2012’ should be interpreted as being identical to a statement that
reads ‘Copyright (c) 2005, 2007, 2008, 2009, 2011, 2012’ and a copyright
statement that reads ‘Copyright (c) 2005-2012’ should be interpreted as being
identical to a statement that reads ‘Copyright (c) 2005, 2006, 2007, 2008,
2009, 2010, 2011, 2012’."
