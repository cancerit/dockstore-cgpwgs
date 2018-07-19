#!/usr/bin/env cwl-runner

class: CommandLineTool

id: "cgpwgs"

label: "CGP WGS analysis flow"

cwlVersion: v1.0

doc: |
  ![build_status](https://quay.io/repository/wtsicgp/dockstore-cgpwgs/status)
  A Docker container for the CGP WXS analysis flow. See the [dockstore-cgpwgs](https://github.com/cancerit/dockstore-cgpwgs)
  website for more information.

  Please read the relevant [changes](https://github.com/cancerit/dockstore-cgpwgs/blob/master/CHANGES.md)
  when upgrading.

  Parameters for a CWL definition are generally described in a json file, but parameters can be provided on the command line.

  To see the parameters descriptions please run: cwltool --tool-help path_to.cwl

  WARNING: The usual setting for 'exclude' is 'NC_007605,hs37d5,GL%' (human GRCh37/NCBI37). Examples
  are configured to run as quickly as possible.

requirements:
  - class: DockerRequirement
    dockerPull: "quay.io/wtsicgp/dockstore-cgpwgs:2.0.1"

hints:
  - class: ResourceRequirement
    coresMin: 1 # works but long, 24 recommended
    ramMin: 32000
    outdirMin: 20000

inputs:
  reference:
    type: File
    doc: "The core reference (fa, fai, dict) as tar.gz"
    inputBinding:
      prefix: -reference
      separate: true

  annot:
    type: File
    doc: "The VAGrENT cache files"
    inputBinding:
      prefix: -annot
      separate: true

  snv_indel:
    type: File
    doc: "Supporting files for SNV and INDEL analysis"
    inputBinding:
      prefix: -snv_indel
      separate: true

  cnv_sv:
    type: File
    doc: "Supporting files for CNV and SV analysis"
    inputBinding:
      prefix: -cnv_sv
      separate: true

  subcl:
    type: File
    doc: "Supporting files for allele counts used by Battenberg Subclonal CNV analysis"
    inputBinding:
      prefix: -subcl
      separate: true

  qcset:
    type: File
    doc: "Supporting files for QC tools"
    inputBinding:
      prefix: -qcset
      separate: true

  tumour:
    type: File
    secondaryFiles:
    - .bas
    doc: "Tumour BAM or CRAM file"
    inputBinding:
      prefix: -tumour
      separate: true

  tumourIdx:
    type: File
    doc: "Tumour alignment file index [bai|csi|crai]"
    inputBinding:
      prefix: -tidx
      separate: true

  normal:
    type: File
    secondaryFiles:
    - .bas
    doc: "Normal BAM or CRAM file"
    inputBinding:
      prefix: -normal
      separate: true

  normalIdx:
    type: File
    doc: "Normal alignment file index"
    inputBinding:
      prefix: -nidx
      separate: true

  exclude:
    type: string
    doc: "Contigs to block during indel analysis"
    inputBinding:
      prefix: -exclude
      separate: true
      shellQuote: true

  species:
    type: string?
    doc: "Species to apply if not found in BAM headers"
    default: ''
    inputBinding:
      prefix: -species
      separate: true
      shellQuote: true

  assembly:
    type: string?
    doc: "Assembly to apply if not found in BAM headers"
    default: ''
    inputBinding:
      prefix: -assembly
      separate: true
      shellQuote: true

  skipbb:
    type: boolean?
    doc: "Skip Battenberg allele counts"
    inputBinding:
      prefix: -skipbb
      separate: true

  pindelcpu:
    type: int?
    doc: "Max cpus for pindel, ignores >8"
    default: 8
    inputBinding:
      prefix: -pindelcpu
      separate: true

  cavereads:
    type: int?
    doc: "Number of reads in a split section for CaVEMan"
    default: 350000
    inputBinding:
      prefix: -cavereads
      separate: true

  purity:
    type: float?
    doc: "Set the purity (rho) for ascat when default solution needs additional guidance. If set ploidy is also required."
    inputBinding:
      prefix: -pu
      separate: true

  ploidy:
    type: float?
    doc: "Set the ploidy (psi) for ascat when default solution needs additional guidance. If set purity is also required."
    inputBinding:
      prefix: -pi
      separate: true


outputs:
  run_params:
    type: File
    outputBinding:
      glob: run.params

  result_archive:
    type: File
    outputBinding:
      glob: WGS_*_vs_*.result.tar.gz

  # named like this so can be converted to a secondaryFile set once supported by dockstore cli
  timings:
    type: File
    outputBinding:
      glob: WGS_*_vs_*.timings.tar.gz

  global_time:
    type: File
    outputBinding:
      glob: WGS_*_vs_*.time

baseCommand: ["/opt/wtsi-cgp/bin/ds-cgpwgs.pl"]

$schemas:
  - http://schema.org/docs/schema_org_rdfa.html

$namespaces:
  s: http://schema.org/

s:codeRepository: https://github.com/cancerit/dockstore-cgpwgs
s:license: https://spdx.org/licenses/AGPL-3.0-only

s:author:
  - class: s:Person
    s:identifier: https://orcid.org/0000-0002-5634-1539
    s:email: mailto:cgphelp@sanger.ac.uk
    s:name: Keiran Raine
