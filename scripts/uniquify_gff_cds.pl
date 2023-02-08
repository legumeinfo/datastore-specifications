#!/usr/bin/env perl

use strict; 
use warnings;
use feature "say";
use Getopt::Long;

my ($check, $verbose, $help);

GetOptions ( 
     "check"   => \$check,
     "verbose" => \$verbose,
     "help"    => \$help,
   );

my $usage = <<EOS;
If sequential CDS IDs are identical in a GFF, adds an incrementing count per ID to make each CDS unique.
Input is via STDIN; output is to STDOUT.

Usage: cat FILE.gff | uniquify_gff_cds.pl 

  -check    Just check and report a total count of all mRNAs with redundant CDS features.
  -verbose  Just check the mRNAs with redundant CDSs. Print them, with the count of each.
  -help     This message
EOS

die "$usage\n" if $help || (-t STDIN);

my %seen_feat;
my $ct = 0;
while ( my $line = <> ) {
  chomp $line;
  if ( $line =~ /^#/ ){ 
    unless ( $check || $verbose ){ say $line }
    next;
  }
  my( @fields ) = split /\t+/, $line;
  if ( $fields[2] =~ /CDS/ || $fields[2] =~ /cDNA_match/ ){
    $fields[8] =~ m/^(ID=[^;]+);(.+)/;
    my ( $cds_id, $ninth_remainder ) = ( $1, $2 );
    if ( $seen_feat{$cds_id} ){
      $ct++;
      unless ( $check || $verbose ){
        say join ("\t", @fields[0 .. 7]), "\t$cds_id", "-$ct;$ninth_remainder";
      }
      $seen_feat{$cds_id}++
    }
    else { # not $seen_feat($cds_id)
      $ct = 1;
      unless ( $check || $verbose ){
        say join("\t", @fields[0 .. 7]), "\t$cds_id", "-$ct;$ninth_remainder";
      }
      $seen_feat{$cds_id}++;
      $ct++;
    }
  }
  else {
    unless ( $check || $verbose ){ say $line; }
  }
}

my $count_nonuniq;
my $count_mRNAs;
if ( $check || $verbose ){
  keys %seen_feat;
  while(my ($k, $v) = each %seen_feat){
    $count_mRNAs++;
    if ($v>1){
      $count_nonuniq++;
      if ( $verbose ){ say "$k:\t$v"; }
    }
  }
  say "Count of mRNAs:\t$count_mRNAs";
  if ($count_nonuniq>0){
    say "Count with non-unique CDSs:\t$count_nonuniq\n";
  }
  else {
    say "No mRNAs have non-unique CDS features.\n";
  }
}

__END__
VERSIONS
S. Cannon
2023-02-08 initial version. Tested on a GenBank RefSeq GFF.


