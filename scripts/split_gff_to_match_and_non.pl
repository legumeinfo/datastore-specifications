#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use feature "say";

my ($list_IDs, $match_out, $non_out, $help, $verbose);

GetOptions (
  "list_IDs=s"  =>  \$list_IDs,   # required
  "match_out=s" =>  \$match_out,  # required
  "non_out=s"   =>  \$non_out,    # required
  "verbose+"    =>  \$verbose,
  "help"        =>  \$help
);

my $usage = <<EOS;
  Usage: cat FILE.gff3 | split_gff_to_match_and_non.pl -list FILE.txt -match MATCH.gff3 -non NON.gff3 [options]
  
  Given a list of IDs and GFF via STDIN, produce two GFFs: one with GFF features 
  matching the list and one with the non-matching features.

  The list can be a simple one-field file of gene identifiers, or a table in which 
  the first column consists of gene identifiers (such as a .fai fasta index file). 

  A typical use case: provide a .fai index file of coding features, and return two GFFs: 
  one with coding features and the other with noncoding features.

  Limitations: This script should only work on sorted gene annotation files.
               List IDs should be gene and/or mRNA names.
   
  Required:
    -list_IDs:  IDs list of IDs, or table with IDs in first column to extract (required)
    -match_out: Filename for GFF to write out for matching features (required)
    -non_out:   Filename for GFF to write out for matching features (required)

  Options:
    -verbose:   (boolean) for more stuff to terminal; may call multiple times
    -help:      for more info
EOS

die "\n$usage\n" if ($help or !defined($list_IDs) or !defined($match_out) or ! defined($non_out) );

# read list in
open( my $LIST_FH, '<', $list_IDs ) or die "can't open list_IDs $list_IDs: $!";

# Put elements of LIST into hash
my %list;

open(my $MATCH_FH, ">", $match_out) or die "Couldn't open out $match_out: $!";
open(my $NON_FH, ">", $non_out) or die "Couldn't open out $non_out: $!";

while (<$LIST_FH>) {
  chomp;
  next if ( $_ =~ /^\s*$/ );
  my $id;
  if ( $_ =~ /^(\S+)\s+\S+/ ){ # If file has more than one field (e.g. a .fai file), use the first field
    $id = $1;
  }
  else { $id = $_ }
  $id =~ s/\s+$//; # strip trailing whitespace
  #say "II id: [$id]";
  $list{$id} = $id; 
}

# Process GFF
my @comments;
my %seen_parent;
my %seen_mRNA;
my %all_genes;
my @all_gff_features;
my @match_gff_features;
while (my $line = <>){
  chomp $line;
  if ($line =~ /^#/){
    if ($line =~ /^#+$/) { next } # skip lines consisting only of '#'
    else { push(@comments, $line); }
    say $MATCH_FH $line;
    next;
  }
  else { # Push all non-comment lines into an array, for later use in extracting the list complement
    push(@all_gff_features, $line);
  }
  my @F = split(/\t/, $line);
  my ($type, $ninth) = ($F[2], $F[8]);
  my @attrs = split(/;/, $ninth);
  $ninth =~ m/ID=([^;]+)/; 
  my $ID = $1;
  my $parent="";
  if ($type =~ /gene/){
    # say "#AA: SEEN GENE: $ID";
    $all_genes{$ID}++;
    if ( $list{$ID}){
      #say "#AA WW ID: $list{$ID}";
      $seen_parent{$ID}++;
      push(@match_gff_features, $line);
    }
    else {
      #say "#AA XX ID: $list{$ID}";
      next;
    }
  }
  elsif ($type =~ /mRNA/) {
    $ninth =~ m/Parent=([^;]+)/;
    $parent = $1;
    # say "#BB: SEEN PAR: $parent";
    if ( $list{$parent}){
      #say "#BB WW parent: $list{$parent}";
      $seen_mRNA{$ID}++;
      $seen_parent{$parent}++;
      push(@match_gff_features, $line);
    }
    else {
      #say "#BB XX parent: $list{$parent}";
      next;
    }
  }
  else { # presume that other components are children of upstream mRNA 
    $ninth =~ m/Parent=([^;]+)/;
    $parent = $1;
    # say "#CC: ID: $ID \t PARENT: $parent";
    if ( $list{$parent} || $seen_parent{$parent} || $seen_mRNA{$parent} ){
      #say "#CC WW parent: $seen_mRNA{$parent}";
      push(@match_gff_features, $line);
    }
    else {
      #say "#CC XX parent: $seen_mRNA{$parent}";
      next;
    }
  }
}

foreach my $line (@match_gff_features){
  say $MATCH_FH $line;
}

# Get complement of list_IDs
my %complement;
foreach my $key (sort keys %all_genes) {
  if (exists $list{$key}){
    say "Main\t$key";
  }
  else {
    $complement{$key}++;
    say "Complement\t$key";
  }
}

# Traverse GFF again, printing records corresponding to the complement
%seen_parent = ();
%seen_mRNA = ();
my @non_gff_features;
foreach my $comment (@comments) {
  say $NON_FH $comment;
}
foreach my $line (@all_gff_features) {
  my @F = split(/\t/, $line);
  my ($type, $ninth) = ($F[2], $F[8]);
  my @attrs = split(/;/, $ninth);
  $ninth =~ m/ID=([^;]+)/; 
  my $ID = $1;
  my $parent="";
  if ($type =~ /gene/){
    # say "#EE: SEEN GENE: $ID";
    if ( $complement{$ID}){
      #say "#EE WW ID: $complement{$ID}";
      $seen_parent{$ID}++;
      push(@non_gff_features, $line);
    }
    else {
      #say "#EE XX ID: $complement{$ID}";
      next;
    }
  }
  elsif ($type =~ /mRNA/) {
    $ninth =~ m/Parent=([^;]+)/;
    $parent = $1;
    # say "#FF: SEEN PAR: $parent";
    if ( $complement{$parent}){
      #say "#FF WW parent: $complement{$parent}";
      $seen_mRNA{$ID}++;
      $seen_parent{$parent}++;
      push(@non_gff_features, $line);
    }
    else {
      #say "#FF XX parent: $complement{$parent}";
      next;
    }
  }
  else { # presume that other components are children of upstream mRNA 
    $ninth =~ m/Parent=([^;]+)/;
    $parent = $1;
    #say "#GG: ID: $ID \t PARENT: $parent";
    if ( $complement{$parent} || $seen_parent{$parent} || $seen_mRNA{$parent} ){
      #say "#GG WW parent: $seen_mRNA{$parent}";
      push(@non_gff_features, $line);
    }
    else {
      #say "#GG XX parent: $seen_mRNA{$parent}";
      next;
    }
  }
}

foreach my $line (@non_gff_features){
  say $NON_FH $line;
}

__END__
VERSIONS
S. Cannon
2025-12-09 Initial version, derived from get_gff_subset.pl

