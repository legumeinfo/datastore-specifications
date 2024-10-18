#!/usr/bin/env perl
  
use warnings;
use strict;
use Getopt::Long;
use utf8;
use open qw( :std :encoding(UTF-8) );
use feature "say";

my $usage = <<EOS;
  Synopsis: ls *gz | write_main.pl -corr FILE.yml -descr FILE.yml -apps FILE.yml [options]

  This script operates on STDIN consisting of a listing of data files to be
  described in the MANIFEST file. Three other files, with simple key-value yaml format,
  provide mappings of filenames (or human-readable suffixes) to the descriptions, applications,
  and correspondences to prior file names. These mappings will be added to the output yaml
  if the keys (in the first column) match filenames in the STDIN.
  
  Required:
    -corr  yaml-format file with correspondences between data filenames and prior names
    -descr yaml-format file with descriptions of data files. The human-readable suffixes may be used as keys,
         cds.fna.gz
         genome_main.fna.gz
    -apps  yaml-format file with applications that will be triggered to use the data. For key values,
        use the human-readable suffixes. For multiple applications for a file type, use comma separation:
          cds.fna.gz: "blast, mines"
          gene_models_exons.gff3.gz: "mines"

  Options:
    -outfile  Specify OUT_FH; otherwise, default to STDOUT.
    -apps  List of applications that will be triggered to use the data. If multiple, separate with commas.
      Example 1:  "jbrowse"
      Example 2:  "mines, blast"
    -prerex  Regular expression for filename prefixes to be ignored when matching files to -corr and -descr data
      These are dot-separated fields. For the LIS/SoyBase/PeanutBase Data Store, data files in most collections
      have four such fields, but annotation collections have five.
      Four fields (default), e.g. glyma.Wm82.gnm2.DTC4  or  glyma.W05_x_C08.qtl.Qi_Li_2014 :
        use "^[^.]+\\.[^.]+\\.[^.]+\\.[^.]+\\."
      Five fields, e.g. glyma.Wm82.gnm2.ann1.RVB6 :
        use "^[^.]+\\.[^.]+\\.[^.]+\\.[^.]+\\.[^.]+\\."
    -verbose  Intermediate output to STDOUT
    -help  This message (boolean).
EOS

my ($corr, $desc, $outfile, $apps, $REX, $verbose, $help);
my $prerex = "^[^.]+\.[^.]+\.[^.]+\.[^.]+\.";
my $lookup_url = 'https://api.fatcat.wiki/v0/release/lookup';
my $overwrite=0;

GetOptions (
  "corr=s" =>    \$corr,
  "desc=s" =>    \$desc,
  "apps=s" =>    \$apps,
  "outfile:s" => \$outfile,
  "prerex:s" =>  \$prerex,
  "verbose" =>   \$verbose,
  "help" =>      \$help,
);

die "$usage" if (@ARGV == 0 && -t STDIN);
die "$usage" unless ($corr && $desc && $apps);
die "$usage" if ($help);

if ($prerex){ $REX=qr/$prerex/ }
else { $REX=qr/^(\S+)/ }

my @applications;
if ($apps){ 
  @applications = split(/,/, $apps);
  s{^\s+|\s+$}{}g foreach @applications; # strip spaces
}

open my $CORFH, "<", $corr or die "Couldn't open in $corr: $!";
open my $DESFH, "<", $desc or die "Couldn't open in $desc: $!";
open my $APPSFH, "<", $apps or die "Couldn't open in $apps: $!";

my $OUT_FH;
if ($outfile) { open ($OUT_FH, ">", $outfile) or die "\nUnable to open output file for writing: $!\n\n"; }

my %corr;
while (<$CORFH>){
  chomp;
  next if $_ =~ /^%|^-|^#|^$/; 
  my ($key, $val) = split(/:/, $_);
  $val =~ s/^ +| +$//;
  # Add value string, keyed to the filename
  $corr{$key} = $val;
  if ($verbose){say "correspondence:  ($key)\t[$val]"}
}
if ($verbose){say ""}

my %desc;
while (<$DESFH>){
  chomp;
  next if $_ =~ /^%|^-|^#|^$/; 
  my ($key, $val) = split(/:/, $_);
  $val =~ s/^ +| +$//;
  $val =~ s/['"]//g;
  # Add value string, keyed to the filename
  $desc{$key} = $val;
  if ($verbose){say "description:  ($key)\t[$val]"}
}
if ($verbose){say ""}

my %apps;
while (<$APPSFH>){
  chomp;
  next if $_ =~ /^%|^-|^#|^$/; 
  my ($key, $val) = split(/:/, $_);
  $val =~ s/^ +| +$//;
  $val =~ s/['"]//g;
  # Add value string, keyed to the filename
  $apps{$key} = $val;
  if ($verbose){say "applications:  ($key)\t[$val]"}
}
if ($verbose){say ""}

&printstr( "---\n" );
while (<STDIN>){
  chomp;
  my $file = $_;

  &printstr( "- name: $file\n" );

  my $file_suffix = $file;
  $file_suffix =~ s/$REX(\S+)/$1/;
  if ($verbose){say "  XXfile_suffix:  $file_suffix"}

  if ($desc{$file}){ &printstr( "  description: $desc{$file}\n" ) }
  elsif ($desc{$file_suffix}){ 
    &printstr( "  description: $desc{$file_suffix}\n" );

    # Print applications, if any are listed for this file type (this $file_suffix)
    if ($apps{$file_suffix}){
      my @apps_array = split(/,/, $apps{$file_suffix});
      s{^\s+|\s+$}{}g foreach @apps_array; # strip spaces
      &printstr( "  applications:\n" );
      for my $apps_str (@apps_array){
        &printstr( "   - $apps_str\n" )
      }
    }  
  }
  else { &printstr( "  description: MISSING\n" ) }

  # Print prior names. In case there are multiple (comma-separated), split and print each.
  if ($corr{$file}){ 
    my $correspondence = $corr{$file};
    my @corr_array = split(/,/, $correspondence);
    s{^\s+|\s+$}{}g foreach @corr_array; # strip spaces
    &printstr( "  prior_names:\n" );
    for my $corr_str (@corr_array){
      &printstr( "   - $corr_str\n" ) 
    }
  }
  elsif ($corr{$file_suffix}){ 
    my $correspondence = $corr{$file_suffix};
    my @corr_array = split(/,/, $correspondence);
    s{^\s+|\s+$}{}g foreach @corr_array; # strip spaces
    &printstr( "  prior_names:\n" );
    for my $corr_str (@corr_array){
      &printstr( "   - $corr_str\n" ) 
    }
  }
}

##################################################
# SUBRUTINES

# Print to outfile or to stdout
sub printstr {
  my $str_to_print = join("", @_);
  if ($outfile) {
    print $OUT_FH $str_to_print;
  }
  else {
    print $str_to_print;
  }
}

__END__

S. Cannon
2024-10-04 Initial version
2024-10-17 Take in regex for filename prefix, and apps for applications related to each file
2024-10-18 Rework handling of applications lists, adding them to the output per file described in the manifest
