#!/bin/bash

# about to do some parallel work...
declare -A do_parallel

TIME_FORMAT='command:%C\\nreal:%e\\nuser:%U\\nsys:%S\\npctCpu:%P\\ntext:%Xk\\ndata:%Dk\\nmax:%Mk\\n';

# declare function to run parallel processing
run_parallel () {
  # adapted from: http://stackoverflow.com/a/18666536/4460430

  rm -f $OUTPUT_DIR/*.wrapper.log

  for key in "${!do_parallel[@]}"; do

    CMD="/usr/bin/time -f $TIME_FORMAT -o $OUTPUT_DIR/timings/${PROTOCOL}_${NAME_MT}_vs_${NAME_WT}.time.$key ${do_parallel[$key]}"

    echo -e "\tStarting $key"
    set -x
    bash -c "$CMD ; echo 'WRAPPER_EXIT: '\$?" >& $OUTPUT_DIR/${key}.wrapper.log&
    set +x
  done

  sleep 10

  set +e
  while true ; do
    ALL_WRAPPERS=`ls -1 $OUTPUT_DIR/*.wrapper.log | wc -l`
    ALL_EXIT=`grep -lF 'WRAPPER_EXIT: ' $OUTPUT_DIR/*.wrapper.log | wc -l`
    BAD_JOBS=`grep -e 'WRAPPER_EXIT: [^0]' $OUTPUT_DIR/*.wrapper.log | wc -l`

    if [ $BAD_JOBS -ne 0 ]; then
      DISPLAY_BAD=`grep -vF 'WRAPPER_EXIT: 0' $OUTPUT_DIR/*.wrapper.log`
      >&2 echo "ERRORS OCCURED: $DISPLAY_BAD"
      exit 1
    fi

    if [ $ALL_WRAPPERS -eq $ALL_EXIT ]; then
      break
    fi
    sleep 15
  done
  set -e

  rm -f $OUTPUT_DIR/*.wrapper.log

  return 0
}

set -e

echo -e "\nStart workflow: `date`\n"

declare -a PRE_EXEC
declare -a POST_EXEC

if [ -z ${PARAM_FILE+x} ] ; then
  PARAM_FILE=$HOME/run.params
fi
echo "Loading user options from: $PARAM_FILE"
if [ ! -f $PARAM_FILE ]; then
  echo -e "\tERROR: file indicated by PARAM_FILE not found: $PARAM_FILE" 1>&2
  exit 1
fi
source $PARAM_FILE

TMP=$OUTPUT_DIR/tmp
mkdir -p $TMP
mkdir -p $OUTPUT_DIR/timings

if [ -z ${CPU+x} ]; then
  CPU=`grep -c ^processor /proc/cpuinfo`
fi

# create area which allows monitoring site to be started, not actively updated until after PRE-EXEC completes
#cp -r /opt/wtsi-cgp/site $OUTPUT_DIR/site

echo -e "\tBAM_MT : $BAM_MT"
echo -e "\tBAM_WT : $BAM_WT"

if [ ${#PRE_EXEC[@]} -eq 0 ]; then
  PRE_EXEC='echo No PRE_EXEC defined'
fi

if [ ${#POST_EXEC[@]} -eq 0 ]; then
  POST_EXEC='echo No POST_EXEC defined'
fi

set -u
mkdir -p $OUTPUT_DIR

# run any pre-exec step before attempting to access BAMs
# logically the pre-exec could be pulling them
if [ ! -f $OUTPUT_DIR/pre-exec.done ]; then
  echo -e "\nRun PRE_EXEC: `date`"

  for i in "${PRE_EXEC[@]}"; do
    set -x
    $i
    { set +x; } 2> /dev/null
  done
  touch $OUTPUT_DIR/pre-exec.done
fi

## get sample names from BAM headers
NAME_MT=`samtools view -H $BAM_MT | perl -ne 'if($_ =~ m/^\@RG/) {($sm) = $_ =~m/\tSM:([^\t]+)/; print "$sm\n";}' | uniq`
NAME_WT=`samtools view -H $BAM_WT | perl -ne 'if($_ =~ m/^\@RG/) {($sm) = $_ =~m/\tSM:([^\t]+)/; print "$sm\n";}' | uniq`

echo -e "\tNAME_MT : $NAME_MT"
echo -e "\tNAME_WT : $NAME_WT"

BAM_MT_TMP=$TMP/$NAME_MT.bam
BAM_WT_TMP=$TMP/$NAME_WT.bam

ln -fs $BAM_MT $BAM_MT_TMP
ln -fs $BAM_WT $BAM_WT_TMP
ln -fs $BAM_MT.bai $BAM_MT_TMP.bai
ln -fs $BAM_WT.bai $BAM_WT_TMP.bai

echo "Setting up Parallel block 1"

if [ ! -f "${BAM_MT}.bas" ]; then
  echo -e "\t[Parallel block 1] BAS $NAME_MT added..."
  do_parallel[bas_MT]="bam_stats -i $BAM_MT_TMP -o $BAM_MT_TMP.bas"
else
  ln -fs $BAM_MT.bas $BAM_MT_TMP.bas
  echo '#PRE EXISTING $NAME_MT.bam.bas file found' > $OUTPUT_DIR/${PROTOCOL}_${NAME_MT}_vs_${NAME_WT}.time.bas_MT
fi

if [ ! -f "${BAM_WT}.bas" ]; then
  echo -e "\t[Parallel block 1] BAS $NAME_WT added..."
  do_parallel[bas_WT]="bam_stats -i $BAM_WT_TMP -o $BAM_WT_TMP.bas"
else
  ln -fs $BAM_WT.bas $BAM_WT_TMP.bas
  echo '#PRE EXISTING $NAME_WT.bam.bas file found' > $OUTPUT_DIR/${PROTOCOL}_${NAME_MT}_vs_${NAME_WT}.time.bas_WT
fi

echo -e "\t[Parallel block 1] Genotype Check added..."
do_parallel[geno]="compareBamGenotypes.pl \
 -o $OUTPUT_DIR/${PROTOCOL}_${NAME_MT}_vs_${NAME_WT}/genotyped \
 -nb $BAM_WT_TMP \
 -j $OUTPUT_DIR/${PROTOCOL}_${NAME_MT}_vs_${NAME_WT}/genotyped/result.json \
 -tb $BAM_MT_TMP"

echo -e "\t[Parallel block 1] VerifyBam Normal added..."
do_parallel[verify_WT]="verifyBamHomChk.pl -d 25 \
  -o $OUTPUT_DIR/${PROTOCOL}_${NAME_WT}/contamination \
  -b $BAM_WT_TMP \
  -j $OUTPUT_DIR/${PROTOCOL}_${NAME_WT}/contamination/result.json"

echo -e "\t[Parallel block 1] BB alleleCount added..."
if [ ! -z ${SKIPBB+x} ]; then
  do_parallel[alleleCount]="echo 'BB allele count disabled by params'"
else
  do_parallel[alleleCount]="battenberg.pl \
    -o $OUTPUT_DIR/${PROTOCOL}_${NAME_MT}_vs_${NAME_WT}/battenberg \
    -u $REF_BASE/battenberg/1000genomesloci \
    -e $REF_BASE/battenberg/impute/impute_info.txt \
    -c $REF_BASE/battenberg/probloci.txt \
    -r $REF_BASE/genome.fa.fai \
    -ig $REF_BASE/battenberg/ignore_contigs.txt \
    -ge XX \
    -tb $BAM_MT_TMP \
    -nb $BAM_WT_TMP \
    -p allelecount \
    -t $CPU"
fi

echo "Starting Parallel block 1: `date`"
run_parallel do_parallel

# unset and redeclare the parallel array ready for block 2
unset do_parallel
declare -A do_parallel
echo -e "\nSetting up Parallel block 2"

echo -e "\t[Parallel block 2] ASCAT added..."
do_parallel[ascat]="ascat.pl \
 -o $OUTPUT_DIR/${PROTOCOL}_${NAME_MT}_vs_${NAME_WT}/ascat \
 -t $BAM_MT_TMP \
 -n $BAM_WT_TMP \
 -sg $REF_BASE/ascat/SnpGcCorrections.tsv \
 -r $REF_BASE/genome.fa \
 -q 20 \
 -g L \
 -rs $SPECIES \
 -ra $ASSEMBLY \
 -pr $PROTOCOL \
 -pl ILLUMINA \
 -c $CPU"

echo -e "\t[Parallel block 2] cgpPindel added..."
do_parallel[cgpPindel]="pindel.pl \
 -o $OUTPUT_DIR/${PROTOCOL}_${NAME_MT}_vs_${NAME_WT}/pindel \
 -r $REF_BASE/genome.fa \
 -t $BAM_MT_TMP \
 -n $BAM_WT_TMP \
 -s $REF_BASE/pindel/simpleRepeats.bed.gz \
 -u $REF_BASE/pindel/pindel_np.gff3.gz \
 -f $REF_BASE/pindel/${PROTOCOL}_Rules.lst \
 -g $REF_BASE/vagrent/codingexon_regions.indel.bed.gz \
 -st $PROTOCOL \
 -as $ASSEMBLY \
 -sp $SPECIES \
 -e $PINDEL_EXCLUDE \
 -b $REF_BASE/pindel/HiDepth.bed.gz \
 -c $CPU \
 -sf $REF_BASE/pindel/softRules.lst"

echo "Starting Parallel block 2: `date`"
run_parallel do_parallel

# prep ascat output for caveman and VerifyBam (Tumour):
set -x
ASCAT_CN="$OUTPUT_DIR/${PROTOCOL}_${NAME_MT}_vs_${NAME_WT}/ascat/$NAME_MT.copynumber.caveman.csv"
perl -ne '@F=(split q{,}, $_)[1,2,3,4]; $F[1]-1; print join("\t",@F)."\n";' < $ASCAT_CN > $TMP/norm.cn.bed
perl -ne '@F=(split q{,}, $_)[1,2,3,6]; $F[1]-1; print join("\t",@F)."\n";' < $ASCAT_CN > $TMP/tum.cn.bed
# ensure no annotated pindel
rm -f $OUTPUT_DIR/${PROTOCOL}_${NAME_MT}_vs_${NAME_WT}/pindel/${NAME_MT}_vs_${NAME_WT}.annot.vcf.gz*
set +x

# unset and redeclare the parallel array ready for block 3
unset do_parallel
declare -A do_parallel
echo -e "\nSetting up Parallel block 3"

echo -e "\t[Parallel block 3] VerifyBam Tumour added..."
do_parallel[verify_MT]="verifyBamHomChk.pl -d 25 \
 -o $OUTPUT_DIR/${PROTOCOL}_$NAME_MT/contamination \
 -b $BAM_MT_TMP \
 -a $OUTPUT_DIR/${PROTOCOL}_${NAME_MT}_vs_${NAME_WT}/ascat/${NAME_MT}.copynumber.caveman.csv \
 -j $OUTPUT_DIR/${PROTOCOL}_${NAME_MT}/contamination/result.json"

echo -e "\t[Parallel block 3] CaVEMan added..."
do_parallel[CaVEMan]="caveman.pl \
 -r $REF_BASE/genome.fa.fai \
 -ig $REF_BASE/caveman/HiDepth.tsv \
 -b $REF_BASE/caveman/flagging \
 -ab $REF_BASE/vagrent \
 -u $REF_BASE/caveman \
 -s $SPECIES \
 -sa $ASSEMBLY \
 -t $CPU \
 -st $PROTOCOL \
 -in $OUTPUT_DIR/${PROTOCOL}_${NAME_MT}_vs_${NAME_WT}/pindel/${NAME_MT}_vs_${NAME_WT}.germline.bed \
 -tc $TMP/tum.cn.bed \
 -nc $TMP/norm.cn.bed \
 -td 5 -nd 2 \
 -tb $BAM_MT_TMP \
 -nb $BAM_WT_TMP \
 -c $SNVFLAG \
 -f $REF_BASE/caveman/flagging/flag.to.vcf.convert.ini \
 -o $OUTPUT_DIR/${PROTOCOL}_${NAME_MT}_vs_${NAME_WT}/caveman"

echo -e "\t[Parallel block 3] BRASS added..."
do_parallel[BRASS]="brass.pl -j 4 -k 4 -c $CPU \
 -d $REF_BASE/brass/HiDepth.bed.gz \
 -f $REF_BASE/brass/brass_np.groups.gz \
 -g $REF_BASE/genome.fa \
 -s '$SPECIES' -as $ASSEMBLY -pr $PROTOCOL -pl ILLUMINA \
 -g_cache $REF_BASE/vagrent/vagrent.cache.gz \
 -vi $REF_BASE/brass/viral.1.1.genomic.fa \
 -mi $REF_BASE/brass/all_ncbi_bacteria.20150703 \
 -b $REF_BASE/brass/500bp_windows.gc.bed.gz \
 -ct $REF_BASE/brass/CentTelo.tsv \
 -t $BAM_MT_TMP \
 -n $BAM_WT_TMP \
 -ss $OUTPUT_DIR/${PROTOCOL}_${NAME_MT}_vs_${NAME_WT}/ascat/*.samplestatistics.txt \
 -o $OUTPUT_DIR/${PROTOCOL}_${NAME_MT}_vs_${NAME_WT}/brass"

 # annotate pindel
 rm -f $OUTPUT_DIR/${PROTOCOL}_${NAME_MT}_vs_${NAME_WT}/pindel/${NAME_MT}_vs_${NAME_WT}.annot.vcf.gz*
 echo -e "\t[Parallel block 3] Pindel_annot added..."
 do_parallel[cgpPindel_annot]="AnnotateVcf.pl -t -c $REF_BASE/vagrent/vagrent.cache.gz \
  -i $OUTPUT_DIR/${PROTOCOL}_${NAME_MT}_vs_${NAME_WT}/pindel/${NAME_MT}_vs_${NAME_WT}.flagged.vcf.gz \
  -o $OUTPUT_DIR/${PROTOCOL}_${NAME_MT}_vs_${NAME_WT}/pindel/${NAME_MT}_vs_${NAME_WT}.annot.vcf"

echo "Starting Parallel block 3: `date`"
run_parallel do_parallel

# unset and redeclare the parallel array ready for block 4
unset do_parallel
declare -A do_parallel

# annotate caveman
rm -f $OUTPUT_DIR/${PROTOCOL}_${NAME_MT}_vs_${NAME_WT}/caveman/${NAME_MT}_vs_${NAME_WT}.annot.muts.vcf.gz*
echo -e "\t[Parallel block 4] CaVEMan_annot added..."
do_parallel[CaVEMan_annot]="AnnotateVcf.pl -t -c $REF_BASE/vagrent/vagrent.cache.gz \
 -i $OUTPUT_DIR/${PROTOCOL}_${NAME_MT}_vs_${NAME_WT}/caveman/${NAME_MT}_vs_${NAME_WT}.flagged.muts.vcf.gz \
 -o $OUTPUT_DIR/${PROTOCOL}_${NAME_MT}_vs_${NAME_WT}/caveman/${NAME_MT}_vs_${NAME_WT}.annot.muts.vcf"

echo "Starting Parallel block 4: `date`"
run_parallel do_parallel

# clean up log files
rm -rf $OUTPUT_DIR/${PROTOCOL}_${NAME_MT}_vs_${NAME_WT}/*/logs

# cleanup battenberg logs
rm -f $OUTPUT_DIR/${PROTOCOL}_${NAME_MT}_vs_${NAME_WT}/battenberg/tmpBattenberg/logs/*

# correct default filenames from contamination jobs
mv $OUTPUT_DIR/timings/${PROTOCOL}_${NAME_MT}_vs_${NAME_WT}.time.verify_WT $OUTPUT_DIR/timings/${PROTOCOL}_${NAME_WT}.time.verify_WT
mv $OUTPUT_DIR/timings/${PROTOCOL}_${NAME_MT}_vs_${NAME_WT}.time.verify_MT $OUTPUT_DIR/timings/${PROTOCOL}_${NAME_MT}.time.verify_MT

echo 'Package results'
# timings first
tar -C $OUTPUT_DIR -zcf ${PROTOCOL}_${NAME_MT}_vs_${NAME_WT}.timings.tar.gz timings
tar -C $OUTPUT_DIR -zcf ${PROTOCOL}_${NAME_MT}_vs_${NAME_WT}.result.tar.gz ${PROTOCOL}_${NAME_MT}_vs_${NAME_WT} ${PROTOCOL}_${NAME_MT} ${PROTOCOL}_${NAME_WT}
cp $PARAM_FILE ${PROTOCOL}_${NAME_MT}_vs_${NAME_WT}.run.params

# run any post-exec step
echo -e "\nRun POST_EXEC: `date`"
for i in "${POST_EXEC[@]}"; do
  set -x
  $i
  set +x
done

echo -e "\nWorkflow end: `date`"
