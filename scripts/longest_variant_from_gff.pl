#!/usr/bin/env perl

use strict; 
use warnings;
use feature "say";
use Getopt::Long;

my ($verbose, $help);

GetOptions ( 
     "verbose" => \$verbose,
     "help"    => \$help,
   );

my $usage = <<EOS;
From a gene annotation file in gff format, report the ID for the longest mRNA for each gene, 
and the parent (gene) ID.

Usage: cat FILE.gff | longest_variant_from_gff.pl

  -verbose  Some intermediate output
  -help     This message
EOS

die "$usage\n" if $help || (-t STDIN);

my @gene_mrna_coords_AoA;
my @F;
while ( my $line = <> ) {
  chomp $line;
  next if ( $line =~ /^#/ );
  my @F = split(/\t+/, $line);
  my ($seqID, $type, $start, $end, $ninth) = ($F[0], $F[2], $F[3], $F[4], $F[8]);
  my @attrs = split(/;/, $ninth);
  if ($type =~ /mRNA/){
    my $ID = $ninth;
    my $parent = $ninth;
    $ID =~ m/ID=([^;]+)/; $ID = $1;
    $parent =~ m/.*arent=([^;]+)/; $parent = $1;
    push @gene_mrna_coords_AoA, [$seqID, $parent, $ID, $start, $end, $end-$start];
  }
}

# Sort the array of arrays by seqID, then by geneID, then by mRNA length (reverse numerically)
my @sorted = sort {
  $a->[0] cmp $b->[0]  # seqID first
         ||
  $a->[1] cmp $b->[1]  # then gene ID
         ||
  $b->[5] <=> $a->[5]  # mRNA length (longest to shortest)
         ||
  $a->[3] <=> $b->[3]  # mRNA start (as tiebreaker if needed)
} @gene_mrna_coords_AoA;


my %seen_gene;
for my $aref ( @sorted ) {
  my ($seqID, $geneID, $mrnaID, $start, $end, $len) = @$aref;
  if ($seen_gene{$geneID}){ # We've seen this gene, so it's not first (and longest)
    if ($verbose){
      say join("\t", "#SKIP", $geneID, $mrnaID, $start, $end, $len );
    }
    next;
  }
  else {
    $seen_gene{$geneID}++;
    say join("\t", $seqID, $geneID, $mrnaID, $start, $end, $len );
  }
}

__END__
VERSIONS
S. Cannon
2023-03-15 initial version. Tested on a GenBank RefSeq GFF.


