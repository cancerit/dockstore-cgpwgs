### 1.0.3
* Export the `PCAP_THREADED_*` variables
* Fixed #8, #9, #10
* Updated base image to pull in fix required for `PCAP_THREADED_LOADBACKOFF`

### 1.0.2
* Update BRASS to handle data that is _very_ quiet
* Fix up the wrapper timings file so it is captured properly
* Upgraded base image to [dockstore-cgpwxs:2.0.4](https://github.com/cancerit/dockstore-cgpwxs/releases/tag/2.0.4)
  * To pick up changes in [cgpPindel:2.2.0](https://github.com/cancerit/cgpPindel/releases/tag/v2.2.0)
* Remove ability to build `*.bas` files as not possible to have optional secondary files and we state expectation of [dockstore-cgpmap](https://github.com/cancerit/dockstore-cgpmap) as data source.
* Moved some processing around to reduce cpu wastage.

### 1.0.1
* Update dependencies to reduce reliance on Capture::Tiny, apparent cause of some issues

### 1.0.0
* Test data in `examples/analysis_config.local.json` moved to a non-expiring location.
* See [dockstore-cgpwxs:2.0.0](https://github.com/cancerit/dockstore-cgpwxs/releases/tag/2.0.0)
* Significant shrinking of image.
* Re-org of exec order to reduce overall runtime.
