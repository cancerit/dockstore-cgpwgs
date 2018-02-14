# CHANGES

## 2.0.0

* Reorganisation to allow access of other tools or necessary bindings
* See dockstore-cgpmap 3.0.0 (primarily adds mismatchQc)
* See dockstore-cgpwxs 3.0.0 (fragment based analysis)
  * You will need to update the reference pack to include the new flagging rules, see example `json`
  files
* Using build stages to shrink images.
* remove legacy PRE/POST-EXEC from cgpbox days

## 1.1.2

* BRASS, random seed fixed to make noisy data have a reproducible result:
  * see [v6.0.4](https://github.com/cancerit/BRASS/releases/tag/v6.0.4)

## 1.1.1

* Stable results between replicate runs:
  * see [v6.0.3](https://github.com/cancerit/BRASS/releases/tag/v6.0.3)
  * took multiple executions of 29 datasets to find this edge-case.

## 1.1.0

BRASS updates

* Significantly reduces the run time of brass_group phase
  * see [v6.0.0](https://github.com/cancerit/BRASS/releases/tag/v6.0.0)
  * Requires new version of the CNV_SV reference archive
* Ensure stable result between replicate runs:
  * see [v6.0.2](https://github.com/cancerit/BRASS/releases/tag/v6.0.2)

Other dependency updates

* Based on [dockstore-cgpwxs:2.1.1](https://github.com/cancerit/dockstore-cgpwxs/releases/tag/2.1.1)
  * Update caveman, pindel and vagrent to improve reproducibility.
  * Reduced I/O in caveman.
* Updates to [alleleCount:v3.3.0](https://github.com/cancerit/alleleCount/releases/tag/v3.3.0) to improve access pattens for dense loci counting, resulting upgrades to:
  * [ascatNgs:v4.1.0](https://github.com/cancerit/ascatNgs/releases)
  * [cgpBattenberg:v3.1.0](https://github.com/cancerit/cgpBattenberg/releases/tag/v3.1.0)

Workflow updates:

* Reorganisation of some processes to reduce run-time:
  * Changes to alleleCount have vastly improved I/O pattern and reduced runtime for
ascat and IMPUTE-allele counts (pre-Battenberg).
  * Reduced number of split files for IMPUTE-allele counts as reduced run time negates need for large spread
  * Reduced alleleCount runtim allowed reorganisation of processes reducing runtime on example data from 23h to 19.5h (28cpu).
* Added `cavereads` to example json specifying a higher value than default to reduce jobs required.

## 1.0.8

* Update [Brass to v5.4.1](https://github.com/cancerit/BRASS/releases/tag/v5.4.1)
  * Provide additional reference file rather than attempt to decode species/build
  due to the may ways a species can be defined.

## 1.0.7

* Update [BRASS to v5.4.0](https://github.com/cancerit/BRASS/releases/tag/v5.4.0)
  * Specifically fixes a vector merge bug which produces warnings (but no apparent change to results).

## 1.0.6

* Fixes #13 - Parsing of sample name from BAM headers fails is sample at end of line
* Update dockstore-cgpwxs to [2.0.7](https://github.com/cancerit/dockstore-cgpwxs/releases/tag/2.0.7) - Fixes bug in pindel core.

## 1.0.5

* Improved handling of CPU oversubscription via PCAP-core update in base image
* Update cgpCaVEManWrapper to expose extra options (specifically split size)

## 1.0.4

Fix an error in param capture test

## 1.0.3

* Export the `PCAP_THREADED_*` variables
* Fixed #8, #9, #10
* Updated base image to pull in fix required for `PCAP_THREADED_LOADBACKOFF`

## 1.0.2

* Update BRASS to handle data that is _very_ quiet
* Fix up the wrapper timings file so it is captured properly
* Upgraded base image to [dockstore-cgpwxs:2.0.4](https://github.com/cancerit/dockstore-cgpwxs/releases/tag/2.0.4)
  * To pick up changes in [cgpPindel:2.2.0](https://github.com/cancerit/cgpPindel/releases/tag/v2.2.0)
* Remove ability to build `*.bas` files as not possible to have optional secondary files and we state expectation of [dockstore-cgpmap](https://github.com/cancerit/dockstore-cgpmap) as data source.
* Moved some processing around to reduce cpu wastage.

## 1.0.1

* Update dependencies to reduce reliance on Capture::Tiny, apparent cause of some issues

## 1.0.0

* Test data in `examples/analysis_config.local.json` moved to a non-expiring location.
* See [dockstore-cgpwxs:2.0.0](https://github.com/cancerit/dockstore-cgpwxs/releases/tag/2.0.0)
* Significant shrinking of image.
* Re-org of exec order to reduce overall runtime.
