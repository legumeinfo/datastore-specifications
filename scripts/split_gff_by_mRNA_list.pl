#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use feature "say";

my ($list_IDs, $match_out, $non_out, $dry_run, $help);

GetOptions (
  "list_IDs=s"     => \$list_IDs,   # required
  "match_out=s"    => \$match_out,  # required
  "non_out=s"      => \$non_out,    # required
  "dry_run"        => \$dry_run,
  "help"           => \$help
);

my $usage = <<EOS;
  Usage: cat FILE.gff3 | split_gff_by_mRNA_list.pl -list FILE.txt -match MATCH.gff3 -non NON.gff3
  
  Given a list of IDs and GFF via STDIN, produce two GFFs: one with GFF features 
  matching the list and one with the non-matching features.

  The list can be a simple one-field file of mRNA identifiers, or a table in which 
  the first column consists of mRNA  identifiers (such as a .fai fasta index file). 

  A typical use case: provide a .fai index file of coding features, and return two GFFs: 
  one with coding features and the other with noncoding features.
  
  Strategy: Preprocess the GFF, generating a hash of mRNA-ID keys and gene-ID values.
  Use that hash to pull gene records for the provided mRNAs into one GFF match file,
  and put all remaining records into the non-match file. Note that the IDs to be provided
  are mRNA IDs, and the gene IDs are determined from the parentage relationship.

  Limitations: This script should only work on sorted gene annotation files.
   
  Required:
    -list_IDs:  list of IDs, or table with IDs in first column to extract (required)
    -match_out: Filename for GFF to write out for matching features (required)
    -non_out:   Filename for GFF to write out for matching features (required)

  Options:
    -dry_run    (boolean) run the program to get report, but don't generate GFF files.
    -help:      (boolean) for this usage info.
EOS

die "\n$usage\n" if ($help or !defined($list_IDs) or !defined($match_out) or ! defined($non_out) );

my $list_filename = basename($list_IDs);
say STDERR "\n==========\nOperating on list file $list_filename";

# read list in
open( my $LIST_FH, '<', $list_IDs ) or die "can't open list_IDs $list_IDs: $!";

# Put elements of LIST into hash
my %list;
my %seen_id;
my $seen_splice_var;
while (<$LIST_FH>) {
  chomp;
  next if ( $_ =~ /^\s*$/ );
  my $id;
  if ( $_ =~ /^(\S+)\s+\S+/ ){ # If file has more than one field (e.g. a .fai file), use the first field
    $id = $1;
  }
  else { $id = $_ }
  $id =~ s/\s+$//; # strip trailing whitespace

  # strip splice variant if present
  unless ($seen_id{$id}) {
    $seen_id{$id}++;
    $list{$id} = $id; 
  }
}

# Process GFF
my @comments; # to store all comment lines
my @features; # to store all feature lines
my %gene_ID;  # hash of gene IDs keyed on mRNA IDs
my %match_IDs; # hash to hold IDs of genes and mRNAs corresponding to the match list
my $ct_orig;
while (my $line = <>){
  chomp $line;
  if ($line =~ /^#/){
    if ($line =~ /^#+$/) { next } # skip lines consisting only of '#'
    else { push(@comments, $line) }
    next;
  }
  else { # Process, store, and count all feature lines
    $ct_orig++;
    push (@features, $line);
    my @F = split(/\t/, $line);
    my ($type, $ninth) = ($F[2], $F[8]);
    my @attrs = split(/;/, $ninth);
    $ninth =~ m/ID=([^;]+)/; 
    my $ID = $1;
    my $parent="";
    if ($type =~ /mRNA/) {
      $ninth =~ m/Parent=([^;]+)/;
      $parent = $1;
      $gene_ID{$ID} = $parent;
      if ($list{$ID}){ 
        $match_IDs{$ID} = $ID;
        $match_IDs{$parent} = $parent;
      }
    }
  }
}

# Traverse all features of GFF again, partitioning the lines into match and nonmatch portions
my ($ct_prev_genes, $ct_new_genes, $ct_match, $ct_non) = (0, 0, 0, 0);
my @match_gff_features;
my @non_gff_features;
my %seen_parent;
my %seen_mRNA;
foreach my $line (@features){
  my @F = split(/\t/, $line);
  my ($type, $ninth) = ($F[2], $F[8]);
  my @attrs = split(/;/, $ninth);
  $ninth =~ m/ID=([^;]+)/;
  my $ID = $1;
  my $parent="";
  if ($type =~ /gene/){
    $ct_prev_genes++;
    if ( $match_IDs{$ID}){
      $seen_parent{$ID}++;
      $ct_new_genes++;
      push(@match_gff_features, $line);
    }
    else {# ID isn't in list, so element must be in the complement
      push(@non_gff_features, $line);
      next;
    }
  }
  elsif ($type =~ /mRNA/) {
    $ninth =~ m/Parent=([^;]+)/;
    $parent = $1;
    if ( $match_IDs{$parent}){
      $seen_mRNA{$ID}++;
      $seen_parent{$parent}++;
      push(@match_gff_features, $line);
    }
    else {# Parent isn't upstream or ID isn't in list, so element must be in the complement
      push(@non_gff_features, $line);
      next;
    }
  }
  else {
    $ninth =~ m/Parent=([^;]+)/;
    $parent = $1;
    if ( $list{$parent} || $seen_parent{$parent} || $seen_mRNA{$parent} ){
      push(@match_gff_features, $line);
    }
    else { # Parent isn't upstream or ID isn't in list, so element must be in the complement
      push(@non_gff_features, $line);
      next;
    }
  }
}

if (scalar(@match_gff_features)>0){
  foreach my $line (@match_gff_features){
    $ct_match++;
  }
}

if (scalar(@non_gff_features)>0){
  my $NON_FH;
  if ($dry_run) { say STDERR "No files generated (dry run), but would write to $non_out" }
  else { open($NON_FH, ">", $non_out) or die "Couldn't open out $non_out: $!" }

  foreach my $comment (@comments) {
    unless ($dry_run) { say $NON_FH $comment }
  }
  foreach my $line (@non_gff_features){
    unless ($dry_run) { say $NON_FH $line }
    $ct_non++;
  }
}
else {
  warn "\nNo non-match features were found, so no such GFF was written.\n";
}

# Report counts in starting and ending GFFs
my $sum = $ct_match+$ct_non;
my $diff = $ct_orig-$sum;
my $diff_genes = $ct_prev_genes-$ct_new_genes;

say STDERR "\nFeature counts in starting and ending GFFs:";
say STDERR "\torig\tmatches\tnon\tsum\tdiff";
say STDERR "==\t$ct_orig\t$ct_match\t$ct_non\t$sum\t$diff";

say STDERR "\nCounts of genes from ...\n\torigGFF\tnewGFF\tdiff";
say STDERR "##\t$ct_prev_genes\t$ct_new_genes\t$diff_genes\n";

if ($ct_match == $sum){
  say STDERR "Only features in the match list were seen, so no new GFF was generated.";
}
else { # write out the match GFF file
  if (scalar(@match_gff_features)>0){
    my $MATCH_FH;
    if ($dry_run) { 
      say STDERR "No files generated (dry run), but would write to $match_out";
      say STDERR "Matches and non-matches were seen, so new GFFs would be generated.";
    }
    else {
      say STDERR "Matches and non-matches were seen, so new GFFs were generated.";
      open($MATCH_FH, ">", $match_out) or die "Couldn't open out $match_out: $!" 
    }
  
    foreach my $comment (@comments) {
      unless ($dry_run) { say $MATCH_FH $comment }
    }
  
    foreach my $line (@match_gff_features){
      unless ($dry_run) { say $MATCH_FH $line }
    }
  }
  else {
    warn "WARNING: No features from the match list were found, so no such GFF was written.\n";
  }
}

if ($diff > 0){
  warn "WARNING: Some GFF features were not accounted for. The sum of matches " .
       "and non-matches should equal the original number of GFF features.\n";
}

if ($diff < 0){
  warn "WARNING: More non-matches than matches were seen. Please check the GFFs";
}

__END__
VERSIONS
S. Cannon
2025-12-13 Initial version, derived from split_gff_by_regex.pl
