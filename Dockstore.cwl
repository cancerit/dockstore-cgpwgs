#!/usr/bin/env cwl-runner

class: CommandLineTool

id: "cgpwxs"

label: "CGP WXS analysis flow"

cwlVersion: v1.0

doc: |
    ![build_status](https://quay.io/repository/wtsicgp/dockstore-cgpwgs/status)
    A Docker container for the CGP WGS analysis flow. See the [dockstore-cgpwgs](https://github.com/cancerit/dockstore-cgpwgs) website for more information.

dct:creator:
  "@id": "http://orcid.org/0000-0002-5634-1539"
  foaf:name: Keiran M Raine
  foaf:mbox: "keiranmraine@gmail.com"

requirements:
  - class: DockerRequirement
    dockerPull: "quay.io/wtsicgp/dockstore-cgpwgs:1.0.0"

hints:
  - class: ResourceRequirement
    coresMin: 1 # works but long, 8 recommended
    ramMin: 32000
    outdirMin: 20000

inputs:
  reference:
    type: File
    doc: "The core reference (fa, fai, dict) as tar.gz"
    inputBinding:
      prefix: -reference
      position: 1
      separate: true

  annot:
    type: File
    doc: "The VAGrENT cache files"
    inputBinding:
      prefix: -annot
      position: 2
      separate: true

  snv_indel:
    type: File
    doc: "Supporting files for SNV and INDEL analysis"
    inputBinding:
      prefix: -snv_indel
      position: 3
      separate: true

  cnv_sv:
    type: File
    doc: "Supporting files for CNV and SV analysis"
    inputBinding:
      prefix: -cnv_sv
      position: 4
      separate: true

  subcl:
    type: File
    doc: "Supporting files for allele counts used by Battenberg Subclonal CNV analysis"
    inputBinding:
      prefix: -subcl
      position: 5
      separate: true

  tumour:
    type: File
    secondaryFiles:
    - .bai
    - .bas
    doc: "Tumour BAM or CRAM file"
    inputBinding:
      prefix: -tumour
      position: 6
      separate: true

  normal:
    type: File
    secondaryFiles:
    - .bai
    - .bas
    doc: "Normal BAM or CRAM file"
    inputBinding:
      prefix: -normal
      position: 7
      separate: true

  exclude:
    type: string
    doc: "Contigs to block during indel analysis"
    inputBinding:
      prefix: -exclude
      position: 8
      separate: true
      shellQuote: true

  species:
    type: string?
    doc: "Species to apply if not found in BAM headers"
    default: ''
    inputBinding:
      prefix: -species
      position: 9
      separate: true
      shellQuote: true

  assembly:
    type: string?
    doc: "Assembly to apply if not found in BAM headers"
    default: ''
    inputBinding:
      prefix: -assembly
      position: 10
      separate: true
      shellQuote: true

outputs:
  run_params:
    type: File
    outputBinding:
      glob: WGS_*_vs_*.run.params

  result_archive:
    type: File
    outputBinding:
      glob: WGS_*_vs_*.tar.gz

  # named like this so can be converted to a secondaryFile set once supported by dockstore cli
  time_bas_MT:
    type: File
    outputBinding:
      glob: WGS_*_vs_*.time.bas_MT

  time_bas_WT:
    type: File
    outputBinding:
      glob: WGS_*_vs_*.time.bas_WT

  time_geno_MT:
    type: File
    outputBinding:
      glob: WGS_*_vs_*.time.geno_MT

  time_verify_WT:
    type: File
    outputBinding:
      glob: WGS_*_vs_*.time.verify_WT

  time_ascat:
    type: File
    outputBinding:
      glob: WGS_*_vs_*.time.ascat

  time_cgpPindel:
    type: File
    outputBinding:
      glob: WGS_*_vs_*.time.cgpPindel

  time_verify_MT:
    type: File
    outputBinding:
      glob: WGS_*_vs_*.time.verify_MT

  time_alleleCount:
    type: File
    outputBinding:
      glob: WGS_*_vs_*.time.alleleCount

  time_CaVEMan:
    type: File
    outputBinding:
      glob: WGS_*_vs_*.time.CaVEMan

  time_BRASS:
    type: File
    outputBinding:
      glob: WGS_*_vs_*.time.BRASS

  time_cgpPindel_annot:
    type: File
    outputBinding:
      glob: WGS_*_vs_*.time.cgpPindel_annot

  time_CaVEMan_annot:
    type: File
    outputBinding:
      glob: WGS_*_vs_*.time.CaVEMan_annot

baseCommand: ["/opt/wtsi-cgp/bin/ds-wrapper.pl"]
