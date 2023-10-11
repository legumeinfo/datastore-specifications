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
If sequential exons IDs are identical in a GFF, adds an incrementing count per ID to make each exon ID unique.
Input is via STDIN; output is to STDOUT.

Usage: cat FILE.gff | uniquify_gff_exon.pl 

  -check    Just check and report a total count of all mRNAs with redundant exon features.
  -verbose  Just check the mRNAs with redundant exons. Print them, with the count of each.
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
  if ( $fields[2] =~ /exon/ ){
    $fields[8] =~ m/^(ID=[^;]+);(.+)/;
    my ( $exon_id, $ninth_remainder ) = ( $1, $2 );
    if ( $seen_feat{$exon_id} ){
      $ct++;
      unless ( $check || $verbose ){
        say join ("\t", @fields[0 .. 7]), "\t$exon_id", "-$ct;$ninth_remainder";
      }
      $seen_feat{$exon_id}++
    }
    else { # not $seen_feat($exon_id)
      $ct = 1;
      unless ( $check || $verbose ){
        say join("\t", @fields[0 .. 7]), "\t$exon_id", "-$ct;$ninth_remainder";
      }
      $seen_feat{$exon_id}++;
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
    say "Count with non-unique exons:\t$count_nonuniq\n";
  }
  else {
    say "No mRNAs have non-unique exon features.\n";
  }
}

__END__
VERSIONS
S. Cannon
2023-10-11 initial version (derived from uniquify_gff_cds.pl. 


