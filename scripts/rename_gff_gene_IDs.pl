#!/usr/bin/env perl

use strict;
use warnings;
use feature "say";
use Getopt::Long;

my $usage = <<EOS;
  Synopsis: gzcat GFF_FILE.gff3.gz | rename_gff_gene_IDs.pl [options] 
       OR     rename_gff_gene_IDs.pl [options] < GFF_FILE.gff3
  
  Read a GFF file from STDIN. 
  Replace the gene IDs with the base portion of the mRNA ID.
  Intended use is for GenBank GFFs, which use unrelated identifiers for the gene and mRNA features.
  For example, if the gene ID=LOC130969383 and mRNA ID=XM_057895071.1, then
  use XM_057895071 as the gene ID.

  NOTE: The GFF input file should be structurally correct and sorted.
  
  Required:
    GFF file in stream via STDIN

  Options:
    -ID_regex  (string) Pattern for the base ID, to capture the portion preceeding e.g. .1 .mRNA.1 
                        Default: '(\\w+)\\.\\d+\$'
    -help      (boolean) This message.
EOS

my $help;
my $ID_regex = '(\w+)\.\d+$';
my $splice_regex = '.+\.(\d+)$';

GetOptions (
  "ID_regex:s" =>  \$ID_regex,
  "help" =>        \$help,
);

die "$usage" if ($help);

my $ID_REX = qr/$ID_regex/;
my $SP_REX = qr/$splice_regex/;

# Read the GFF contents. Store for later use, and remember ID :: Name pairs for mRNA features
my (%id_mRNA_of_gene, @whole_gff);
while (<STDIN>) {
  s/\r?\n\z//; # CRLF to LF
  chomp;
  push(@whole_gff, $_);
  next if ($_ =~ /^#/);
  next if ($_ =~ /cDNA_match/); # These features in GenBank GFFs don't have proper gene structure. Skip.
  
  my @fields = split(/\t/, $_);
  my @attrs = split(/;/, $fields[8]);
  if ($fields[2] =~ /CDS|exon|region|gene|pseudogene/){ 
    next;  # skip region, gene, and lower sub-features. This leaves mRNA, rRNA, transcript, tRNA, 
  }
  else { # mRNA and similar features directly below gene
    my ($ID, $mRNA_ID_base, $Name, $Parent);
    foreach my $attr (@attrs){
      my ($k, $v) = split(/=/, $attr);
      if ($k =~ /\bID/){ $ID = $v }
      elsif ($k =~ /\bName/){ $Name = $v }
      elsif ($k =~ /\bParent/){ $Parent = $v }
      else {  }
      $mRNA_ID_base = $ID;
      $mRNA_ID_base =~ s/$ID_REX/$1/;
    }
    $id_mRNA_of_gene{$Parent} = $mRNA_ID_base;
    # say "AA: ID=$ID\tmRNA_ID_base=$mRNA_ID_base\tParent=$Parent\tid_mRNA_of_gene=$id_mRNA_of_gene{$Parent}";
  }
}

say "";

# Process the GFF contents
my $comment_string = "";
my ($gene_name, $new_ID);
my ($prev_ID, $prev_Parent, $new_gene_ID, $mRNA_ID_base);
my $tcpt_ct = 0;
foreach my $line (@whole_gff) {
  if ($line =~ /(^#.+)/) { # print comment line 
    say $1;
  }
  else { # body of the GFF
    my @fields = split(/\t/, $line);
    
    next if ($line =~ /cDNA_match/); # These features in GenBank GFFs don't have proper gene structure. Skip.

    my $ninth = $fields[8];
    my @attrs = split(/;/, $ninth);
    my ($ID, $Name, $Parent);
    foreach my $attr (@attrs){
      my ($k, $v) = split(/=/, $attr);
      if ($k =~ /\bID/){ $ID = $v }
      elsif ($k =~ /\bName/){ $Name = $v }
      elsif ($k =~ /\bParent/){ $Parent = $v }
    }

    if ($fields[2] eq "gene"){  # Handle pseudogene records separately
      $tcpt_ct = 0;
      $new_gene_ID = $id_mRNA_of_gene{$ID};
      say join("\t", @fields[0..7], "ID=$new_gene_ID;Name=$new_gene_ID;locus=$ID");
      $Parent = $new_gene_ID;
    }
    elsif ($fields[2] =~ /mRNA/){
      $tcpt_ct++;
      $new_ID = "$Name";
      $Parent = $new_ID;
      $Parent =~ s/$ID_REX/$1/;
      say join("\t", @fields[0..7], "ID=$new_ID;Name=$Name;Parent=$Parent");
    }
    else { # feature is something other than gene or mRNA
      say join("\t", @fields[0..7], $ninth);
    }
  }
}

__END__

Steven Cannon
Versions
v01 2024-01-14 New script. 


