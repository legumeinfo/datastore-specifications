#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use feature "say";

my ($list_IDs, $help, $verbose);

GetOptions (
  "list_IDs=s" => \$list_IDs,   # required
  "verbose+" =>   \$verbose,
  "help" =>       \$help
);

my $usage = <<EOS;
  Usage: cat FILE.gff3 | get_gff_subset.pl -list FILE.txt [-options] 
  
  Given a list of feature IDs and GFF via STDIN, filter the GFF to include only listed features and their children.

  Limitations: This script should only work on sorted gene annotation files.
               List IDs should be gene and/or mRNA names.
   
   -list_IDs: list of IDs to extract (required)
   -verbose    (boolean) for more stuff to terminal; may call multiple times
   -help       for more info
   
EOS

die "\n$usage\n" if ($help or !defined($list_IDs) );

# read list in
open( my $LIST_FH, '<', $list_IDs ) or die "can't open list_IDs $list_IDs: $!";

# Put elements of LIST into hash
my %list;

while (<$LIST_FH>) {
  chomp;
  next if ( $_ =~ /^\s*$/ );
  my $id = $_;
  $id =~ s/\s+$//; # strip trailing whitespace
  #say "II id: [$id]";
  $list{$id} = $id; 
}

# Process GFF
my %seen_parent;
my %seen_mRNA;
while (my $line = <>){
  chomp $line;
  if ($line =~ /^#/){
    say $line;
    next;
  }
  my @F = split(/\t/, $line);
  my ($type, $ninth) = ($F[2], $F[8]);
  my @attrs = split(/;/, $ninth);
  my $ID;
  my $parent="";
  if ($type =~ /gene/){
    $ninth =~ m/ID=([^;]+)/; 
    $ID = $1;
    if ($verbose){ say "#AA: SEEN GENE: $ID" }
    if ( $list{$ID}){
      #say "#AA WW ID: $list{$ID}";
      $seen_parent{$ID}++;
      say $line;
    }
    else {
      #say "#AA XX ID: $list{$ID}";
      next;
    }
  }
  elsif ($type =~ /mRNA/) {
    $ninth =~ m/ID=([^;]+)/;
    $ID = $1;
    $ninth =~ m/Parent=([^;]+)/;
    $parent = $1;
    if ($verbose){ say "#BB: SEEN PAR: $parent" }
    if ( $list{$parent}){
      #say "#BB WW parent: $list{$parent}";
      $seen_mRNA{$ID}++;
      $seen_parent{$parent}++;
      say $line;
    }
    else {
      #say "#BB XX parent: $list{$parent}";
      next;
    }
  }
  else { # presume that other components are children of upstream mRNA 
    $ninth =~ m/ID=([^;]+)/;
    $ID = $1;
    $ninth =~ m/Parent=([^;]+)/;
    $parent = $1;
    if ($verbose){ say "#CC: ID: $ID \t PARENT: $parent" }
    if ( $list{$parent} || $seen_parent{$parent} || $seen_mRNA{$parent} ){
      #say "#CC WW parent: $seen_mRNA{$parent}";
      say $line;
    }
    else {
      #say "#CC XX parent: $seen_mRNA{$parent}";
      next;
    }
  }
}
  
__END__
VERSIONS
S. Cannon
2023-03-18 Initial version

