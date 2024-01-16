#!/usr/bin/env perl

use strict;
use warnings;
use feature "say";
use Getopt::Long;

my $usage = <<EOS;
  Synopsis: cat GFF_FILE.gff3 | rename_gff_mRNA_IDs.pl [options] 
       OR     rename_gff_mRNA_IDs.pl [options] < GFF_FILE.gff3
  
  Read a GFF file from STDIN. 
  Replace the mRNA IDs with the parent gene ID (retaining the splice variant suffix in the mRNA)

  Intended use is for GenBank GFFs, which use unrelated identifiers for the gene and mRNA features.
  For example, if the gene ID=LOC130969383 and mRNA ID=XM_057895071.1, then
  use XM_057895071 as the gene ID.

  Note: the output is NOT SORTED. Use e.g. sort_gff.pl on the output.

  The GFF input file should be structurally correct and sorted.

  Example, for a GenBank GFF - first simplifying the GFF and then replacing 
  GenBank's locus IDs with the base of the mRNA IDs:

    hash_into_gff_id.pl -gff genomic.gff -seqid_map init_seqid_map.tsv |
      simplify_genbank_gff.sh |
      rename_gff_mRNA_IDs.pl | sort_gff.pl > genomic.modID.gff
  
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
my (%id_mRNA_of_gene, @whole_gff, %gene_record);
my @provisional_gff;  # Use this to accumulate the new GFF. It may have extra gene records, which will be pruned at the end.
while (<STDIN>) {
  s/\r?\n\z//; # CRLF to LF
  chomp;
  push(@whole_gff, $_);
  next if ($_ =~ /^#/);
  
  my @fields = split(/\t/, $_);
  my @attrs = split(/;/, $fields[8]);
  if ($fields[2] =~ /CDS|exon|region|gene|pseudogene|cDNA_match/){ 
    next;  # skip region, gene, and lower sub-features. This leaves mRNA, rRNA, transcript
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

    # Make a gene record for this feature, to be used only if the GFF has none.
    my $attr_string = "ID=$mRNA_ID_base;Name=$mRNA_ID_base;locus=$ID";
    $gene_record{$mRNA_ID_base} = join("\t", @fields[0..1], "gene", @fields[4..7], $attr_string);
    # say "BB: $gene_record{$mRNA_ID_base}";
  }
}

# Process the GFF contents
my $comment_string = "";
my ($new_ID, $new_gene_ID, %seen_mRNA_base,%seen_pseudogene);
my $tcpt_ct = 0;
my ($mRNA_ID_base, $new_mRNA_ID);
foreach my $line (@whole_gff) {
  if ($line =~ /(^#.+)/) { # print comment line 
    say $line;
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

    if ($line =~ /pseudogene/){ # These lack mRNA records. Exclude them and their sub-features (exons).
      $seen_pseudogene{$ID} = $ID;
      next;
    }

    if ($line =~ /tRNA/i){ # GenBank record structure seems OK for these. Just print.
      say join("\t", @fields[0..8]);
      next;
    }
    
    my $mRNA_ID;
    if ($fields[2] eq "gene" | $fields[2] =~ /region/){ 
      $tcpt_ct = 0;
      say join("\t", @fields[0..8]);
    }
    elsif ($fields[2] =~ /mRNA|transcript|lnc_RNA|snoRNA|snRNA|rRNA/) {
      $tcpt_ct++;
      $mRNA_ID = $ID;
      $mRNA_ID_base = $ID;
      $mRNA_ID_base =~ s/$ID_REX/$1/;
      $seen_mRNA_base{$mRNA_ID_base}++;
      $new_mRNA_ID = "$Parent.$tcpt_ct";
      say join("\t", @fields[0..7], "ID=$new_mRNA_ID;Name=$new_mRNA_ID;Parent=$Parent");
    }
    elsif ($fields[2] =~ /exon/) {
      if ($seen_pseudogene{$Parent}){
        next;
      }
      else {
        $ID =~ /(exon)-(.+)\.\d+-(\d+)$/;
        my $new_ID = "$1-$new_mRNA_ID-$3";
        #say "CC: ID=$ID";
        #say "DD: new_ID=$new_ID";
        say join("\t", @fields[0..7], "ID=$new_ID;Name=$Parent.$tcpt_ct;Parent=$Parent");
      }
    }
    else {
      $ID =~ /(.+)\.\d+-(\d+)$/;
      my $new_ID = "$new_mRNA_ID-$2";
      #say "EE: ID=$ID";
      #say "FF: new_ID=$new_ID";
      say join("\t", @fields[0..7], "ID=$new_ID;Name=$Parent.$tcpt_ct;Parent=$Parent");
    }
  }
}

__END__

Steven Cannon
Versions
2024-01-16 New script.

