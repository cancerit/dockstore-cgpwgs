#!/usr/bin/perl

use strict;
use Getopt::Long;
use File::Path qw(make_path);
use Pod::Usage qw(pod2usage);
use Data::Dumper;
use autodie qw(:all);
use warnings FATAL => 'all';

pod2usage(-verbose => 1, -exitval => 1) if(@ARGV == 0);

# set defaults
my %opts = ();

GetOptions( 'h|help' => \$opts{'h'},
            'm|man' => \$opts{'m'},
            'r|reference=s' => \$opts{'r'},
            'a|annot=s' => \$opts{'a'},
            'si|snv_indel=s' => \$opts{'si'},
            'cs|cnv_sv=s' => \$opts{'cs'},
            'sc|subcl=s' => \$opts{'sc'},
            't|tumour=s' => \$opts{'t'},
            'n|normal=s' => \$opts{'n'},
            'e|exclude=s' => \$opts{'e'},
            'sp|species=s' => \$opts{'sp'},
            'as|assembly=s' => \$opts{'as'},
            'sf|snvflag=s' => \$opts{'sf'},
) or pod2usage(2);

pod2usage(-verbose => 1, -exitval => 0) if(defined $opts{'h'});
pod2usage(-verbose => 2, -exitval => 0) if(defined $opts{'m'});

delete $opts{'h'};
delete $opts{'m'};
delete $opts{'sp'} if(! defined $opts{'sp'}  || length $opts{'sp'} == 0);
delete $opts{'as'} if(! defined $opts{'as'}  || length $opts{'as'} == 0);

## read species/assembly from bam headers
my ($mt_species, $mt_assembly) = species_assembly_from_xam($opts{'t'});
my ($wt_species, $wt_assembly) = species_assembly_from_xam($opts{'n'});
if($mt_species ne $wt_species) {
  warn "WARN: Species mismatch between T/N [CR|B]AM headers\n";
  if(!defined $opts{'sp'}) {
    die "ERROR: Please define species to handle this mismatch\n";
  }
}
elsif($mt_species ne q{}) {
  $opts{'sp'} = $mt_species;
}
if(!defined $opts{'sp'}) {
  die "ERROR: Please define species, not found in [CR|B]AM headers.\n";
}

if($mt_assembly ne $wt_assembly) {
  warn "WARN: Assembly mismatch between T/N [CR|B]AM headers\n";
  if(!defined $opts{'as'}) {
    die "ERROR: Please define assembly to handle this mismatch\n";
  }
}
elsif($mt_assembly ne q{}) {
  $opts{'as'} = $mt_assembly;
}
if(!defined $opts{'as'}) {
  die "ERROR: Please define assembly, not found in [CR|B]AM headers.\n";
}

printf "Options loaded: \n%s\n",Dumper(\%opts);

## unpack the reference area:
my $ref_area = $ENV{HOME}.'/reference_files';

ref_unpack($ref_area, $opts{'r'});
ref_unpack($ref_area, $opts{'a'});
ref_unpack($ref_area, $opts{'si'});
ref_unpack($ref_area, $opts{'cs'});
ref_unpack($ref_area, $opts{'sc'});

## now complete the caveman flaging file correctly
my $ini = add_species_flag_ini($opts{'sp'}, "$ref_area/caveman/flag.vcf.config.WGS.ini");

my $run_file = $ENV{HOME}.'/run.params';
open my $FH,'>',$run_file or die "Failed to write to $run_file: $!";
# Force explicit checking of file flush
print $FH "PCAP_THREADED_NO_SCRIPT=1\n";
print $FH "PCAP_THREADED_FORCE_SYNC=1\n";
print $FH "PCAP_THREADED_LOADBACKOFF=1\n";
# hard-coded
printf $FH "PROTOCOL=WGS\n";
# required options
printf $FH "OUTPUT_DIR='%s'\n", $ENV{HOME};
printf $FH "REF_BASE='%s'\n", $ref_area;
printf $FH "BAM_MT='%s'\n", $opts{'t'};
printf $FH "BAM_WT='%s'\n", $opts{'n'};
printf $FH "PINDEL_EXCLUDE='%s'\n", $opts{'e'};
printf $FH "SPECIES='%s'\n", $opts{'sp'};
printf $FH "ASSEMBLY='%s'\n", $opts{'as'};
printf $FH "SNVFLAG='%s'\n", $ini;
close $FH;

exec('analysisWGS.sh'); # I will never return to the perl code

sub add_species_flag_ini {
  my ($species, $ini_in) = @_;
  $species =~ s/ /_/g;
  my $ini_out = $ENV{HOME}.'/flag.vcf.config.WGS.ini';
  open my $IN, '<', $ini_in;
  open my $OUT,'>',$ini_out;
  while(my $line = <$IN>) {
    $line =~ s/^\[/[$species/;
    print $OUT $line;
  }
  close $OUT;
  close $IN;
  return $ini_out;
}

sub species_assembly_from_xam {
  my $xam = shift;
  my %assembly_set;
  my %species_set;
  open my $SAM, '-|', "samtools view -H $xam" or die $!;
  while(my $line = <$SAM>) {
    next unless($line =~ m/^\@SQ/);
    chomp $line;
    $line .= "\t"; # simplify matching
    if($line =~ m/\tAS:([^\t]+)\t/) {
      $assembly_set{$1}++;
    }
    if($line =~ m/\SP:([^\t]+)\t/) {
      $species_set{$1}++;
    }
  }
  close $SAM;
  my $species = q{};
  my $max_val = 0;
  for(keys %species_set) {
    if($species_set{$_} > $max_val) {
      $max_val = $species_set{$_};
      $species = $_;
    }
  }
  my $assembly = q{};
  $max_val = 0;
  for(keys %assembly_set) {
    if($assembly_set{$_} > $max_val) {
      $max_val = $assembly_set{$_};
      $assembly = $_;
    }
  }
  return ($species, $assembly);
}

sub ref_unpack {
  my ($ref_area, $item) = @_;
  make_path($ref_area) unless(-d $ref_area);
  my $untar = sprintf 'tar --strip-components 1 -C %s -zxvf %s', $ref_area, $item;
  system($untar) && die $!;
  return 1;
}

__END__


=head1 NAME

dh-wrapper.pl - Generate the param file and execute analysisWGS.sh (for dockstore)

=head1 SYNOPSIS

dh-wrapper.pl [options] [file(s)...]

  Required parameters:
    -reference   -r   Path to core reference tar.gz
    -annot       -a   Path to VAGrENT*.tar.gz
    -snv_indel   -si  Path to SNV_INDEL*.tar.gz
    -cnv_sv      -cs  Path to CNV_SV*.tar.gz
    -subcl       -sc  Path to SUBCL*.tar.gz
    -tumour      -t   Tumour [CR|B]AM file
    -normal      -n   Normal [CR|B]AM file
    -exclude     -e   Exclude these contigs from pindel analysis
                        e.g. NC_007605,hs37d5,GL%

  Optional parameters
    -species     -sp  Species name (may require quoting)
    -assembly    -a   Reference assembly

  Other:
    -help        -h   Brief help message.
    -man         -m   Full documentation.

=head1 DESCRIPTION

Wrapper script to map dockstore cwl inputs to PARAMS file used by underlying code.

=head1 OPTION DETAILS

=over 4

=item B<-reference>

Path to mapping tar.gz reference files

=item B<-annot>

Path to VAGrENT*.tar.gz

=item B<-snv_indel>

Path to Path to SNV_INDEL*.tar.gz

=item B<-cnv_sv>

Path to Path to CNV_SV*.tar.gz

=item B<-subcl>

Path to Path to SUBCL*.tar.gz

=item B<-tumour>

Path to tumour BAM or CRAM file with co-located index and BAS file.

=item B<-normal>

Path to normal BAM or CRAM file with co-located index and BAS file.

=item B<-exclude>

Contigs to be excluded from Pindel analysis, csv, use '%' for wildcard.

=item B<-species>

Specify overriding species, by default will select the most prevelant entry in
[CR|B]AM header (to cope with inclusion of viral/decoy sequences).

=item B<-assembly>

Specify overriding assembly, by default will select the most prevelant entry in
[CR|B]AM header (to cope with inclusion of viral/decoy sequences).

=back

=cut
