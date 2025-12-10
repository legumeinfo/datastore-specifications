#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use feature "say";

my ($list_IDs, $match_out, $non_out, $dry_run, $help);
my $splice_regex = "\\.\\d+\$";

GetOptions (
  "list_IDs=s"     => \$list_IDs,   # required
  "match_out=s"    => \$match_out,  # required
  "non_out=s"      => \$non_out,    # required
  "splice_regex:s" => \$splice_regex,
  "dry_run"        => \$dry_run,
  "help"           => \$help
);

my $usage = <<EOS;
  Usage: cat FILE.gff3 | split_gff_to_match_and_non.pl -list FILE.txt -match MATCH.gff3 -non NON.gff3
  
  Given a list of IDs and GFF via STDIN, produce two GFFs: one with GFF features 
  matching the list and one with the non-matching features.

  The list can be a simple one-field file of gene identifiers, or a table in which 
  the first column consists of gene identifiers (such as a .fai fasta index file). 

  Note that the GENE IDs are used; if mRNA IDs are provided, the splice form
  will be stripped. If the splice form has an unusual form (other than .#), provide
  a regex to use for identifying the genic portion of the ID.

  A typical use case: provide a .fai index file of coding features, and return two GFFs: 
  one with coding features and the other with noncoding features.

  Limitations: This script should only work on sorted gene annotation files.
               List IDs should be gene and/or mRNA names.
   
  Required:
    -list_IDs:  IDs list of IDs, or table with IDs in first column to extract (required)
    -match_out: Filename for GFF to write out for matching features (required)
    -non_out:   Filename for GFF to write out for matching features (required)

  Options:
    -splice_regex:   (string) regular expression to use to exclude the splice variant suffix 
       of a feature name during the match. Not needed if gene IDs are provided in the list.
         DEFAULT for transcripts like Gene1234.1, the dot and trailing digits will be stripped: "\\.\\d+\$"  
         Example 2: For transcripts like Gene1234-mRNA-1, use "-mRNA-\\d+\$" 
         Example 3: For proteins like    Gene1234.1.p,    use "\\.\\d+\\.p\$"
    -dry_run    (boolean) run the program to get report, but don't generate GFF files.
    -help:      (boolean) for this usage info.
EOS

die "\n$usage\n" if ($help or !defined($list_IDs) or !defined($match_out) or ! defined($non_out) );

my $SPL_RX=qr/$splice_regex/;

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
  if ($id =~ /(.+)($SPL_RX)$/){ $seen_splice_var++ }
  $id =~ s/(.+)($SPL_RX)$/$1/;
  unless ($seen_id{$id}) {
    $seen_id{$id}++;
    $list{$id} = $id; 
  }
}

# Process GFF
my ($ct_orig, $ct_match, $ct_non) = (0, 0, 0);
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
    else { push(@comments, $line) }
    next;
  }
  else { # Push all non-comment lines into an array, for later use in extracting the list complement
    push(@all_gff_features, $line);
    $ct_orig++;
  }
  my @F = split(/\t/, $line);
  my ($type, $ninth) = ($F[2], $F[8]);
  my @attrs = split(/;/, $ninth);
  $ninth =~ m/ID=([^;]+)/; 
  my $ID = $1;
  my $parent="";
  if ($type =~ /gene/){
    $all_genes{$ID}++;
    if ( $list{$ID}){
      $seen_parent{$ID}++;
      push(@match_gff_features, $line);
    }
    else {
      next;
    }
  }
  elsif ($type =~ /mRNA/) {
    $ninth =~ m/Parent=([^;]+)/;
    $parent = $1;
    if ( $list{$parent}){
      $seen_mRNA{$ID}++;
      $seen_parent{$parent}++;
      push(@match_gff_features, $line);
    }
    else {
      next;
    }
  }
  else { # presume that other components are children of upstream mRNA 
    $ninth =~ m/Parent=([^;]+)/;
    $parent = $1;
    if ( $list{$parent} || $seen_parent{$parent} || $seen_mRNA{$parent} ){
      push(@match_gff_features, $line);
    }
    else {
      next;
    }
  }
}

if (scalar(@match_gff_features)>0){
  my $MATCH_FH;
  if ($dry_run) { say STDERR "No files generated (dry run), but would write to $match_out" }
  else {open($MATCH_FH, ">", $match_out) or die "Couldn't open out $match_out: $!" }

  foreach my $comment (@comments) {
    unless ($dry_run) { say $MATCH_FH $comment }
  }

  foreach my $line (@match_gff_features){
    unless ($dry_run) { say $MATCH_FH $line }
    $ct_match++;
  }
}
else {
  warn "\nNo features from the match list were found, so no such GFF was written.\n";
}

# Get complement of list_IDs
my %complement;
foreach my $key (sort keys %all_genes) {
  if (exists $list{$key}){
  }
  else {
    $complement{$key}++;
  }
}

# Traverse GFF again, printing records corresponding to the complement
%seen_parent = ();
%seen_mRNA = ();
my @non_gff_features;
foreach my $line (@all_gff_features) {
  my @F = split(/\t/, $line);
  my ($type, $ninth) = ($F[2], $F[8]);
  my @attrs = split(/;/, $ninth);
  $ninth =~ m/ID=([^;]+)/; 
  my $ID = $1;
  my $parent="";
  if ($type =~ /gene/){
    if ( $complement{$ID}){
      $seen_parent{$ID}++;
      push(@non_gff_features, $line);
    }
    else {
      next;
    }
  }
  elsif ($type =~ /mRNA/) {
    $ninth =~ m/Parent=([^;]+)/;
    $parent = $1;
    if ( $complement{$parent}){
      $seen_mRNA{$ID}++;
      $seen_parent{$parent}++;
      push(@non_gff_features, $line);
    }
    else {
      next;
    }
  }
  else { # presume that other components are children of upstream mRNA 
    $ninth =~ m/Parent=([^;]+)/;
    $parent = $1;
    if ( $complement{$parent} || $seen_parent{$parent} || $seen_mRNA{$parent} ){
      push(@non_gff_features, $line);
    }
    else {
      next;
    }
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
if ($seen_splice_var){
  say STDERR "\nIn match list, splice variants of form $SPL_RX were seen $seen_splice_var times and stripped.";
}
else {
  say STDERR "\nIn match list, no splice variant was seen, so items were treated as gene IDs.";
}
say STDERR "\nFeature counts in starting and ending GFFs:";
say STDERR "\torig\tmatches\tnon\tsum\tdiff";
say STDERR "\t$ct_orig\t$ct_match\t$ct_non\t$sum\t$diff\n";

if ($diff > 0){
  warn "\nWARNING: Some GFF features were not accounted for. The sum of matches " .
       "and non-matches should equal the original number of GFF features.\n";
}

__END__
VERSIONS
S. Cannon
2025-12-09 Initial version, derived from get_gff_subset.pl
2025-12-10 Report results, and code cleanup. Add method to strip splice variants from mRNA IDs.

