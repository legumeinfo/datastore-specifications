#!/usr/bin/env perl

# PROGRAM: vcf2gff.pl
# VERSION: see version notes at bottom of file.
# S. Cannon 2020
# see description under Usage

use strict;
use warnings;
use Getopt::Long;

####### File IO ########

my $source="SOURCE";
my $feature="genetic_marker";
my $prefix="PREFIX";
my $build_ID;
my $help;

GetOptions (
  "source:s"    => \$source,
  "feature:s"   => \$feature,
  "prefix:s" => \$prefix,
  "build_ID"    => \$build_ID,
  "help"        => \$help
);

my $usage = <<EOS;
  Usage: cat FILE.vcf | $0 [-options]
  
  Given a VCF file (on STDIN), generate a GFF from the marker and position data.
   
  Options:
  -source    String for the second field of the GFF
  -feature   String for the third field of the GFF. Default "genetic_marker"
  -prefix Prefix for the SNP name, after "ID=", in the attribute column
  -build_ID  (bool) Build ID from CHROM and POS (col1 and 2)
  -help      (bool) for more info
EOS

die "\n$usage\n" if ($help);

while (<>) {
  chomp;
  my @parts = split(/\t/, $_);
  my ($CHROM, $POS, $ID, $REF, $ALT) = ($parts[0], $parts[1], $parts[2], $parts[3], $parts[4]);

  next if ($_=~/^#/);
  if (not $build_ID){
    print "$prefix.$CHROM\t$source\t$feature\t$POS\t$POS\t.\t.\t.\tID=$prefix.$ID;Name=$ID;alleles=$REF/$ALT\n";
  }
  else { # $build_ID is true, so construct ID from columns 1 and 2
    $ID = $CHROM . "_" . $POS;
    print "$prefix.$CHROM\t$source\t$feature\t$POS\t$POS\t.\t.\t.\tID=$prefix.$ID;Name=$ID;alleles=$REF/$ALT\n";
  }
}

__END__
VERSIONS

v0.01 2020-12-22 Initial working version
v0.02 2022-04-01 Add option "-build_ID" to construct marker IDs as e.g. Chr01.1234

