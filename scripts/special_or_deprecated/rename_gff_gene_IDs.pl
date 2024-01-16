#!/usr/bin/env perl

use strict;
use warnings;
use feature "say";
use Getopt::Long;

my $usage = <<EOS;
  Synopsis: cat GFF_FILE.gff3 | rename_gff_gene_IDs.pl [options] 
       OR     rename_gff_gene_IDs.pl [options] < GFF_FILE.gff3
  
  Read a GFF file from STDIN. 
  Replace the gene IDs with the base portion of the mRNA ID.

  Intended use is for GenBank GFFs, which use unrelated identifiers for the gene and mRNA features.
  For example, if the gene ID=LOC130969383 and mRNA ID=XM_057895071.1, then
  use XM_057895071 as the gene ID.

  Note: the output is NOT SORTED. Use e.g. sort_gff.pl on the output.

  The GFF input file should be structurally correct and sorted.

  Example, for a GenBank GFF - first simplifying the GFF and then replacing 
  GenBank's locus IDs with the base of the mRNA IDs:

    hash_into_gff_id.pl -gff genomic.gff -seqid_map init_seqid_map.tsv |
      simplify_genbank_gff.sh |
      rename_gff_gene_IDs.pl | sort_gff.pl > genomic.modID.gff
  
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

    # Make a gene record for this feature, to be used only if the GFF has none.
    my $attr_string = "ID=$mRNA_ID_base;Name=$mRNA_ID_base;locus=$ID";
    $gene_record{$mRNA_ID_base} = join("\t", @fields[0..1], "gene", @fields[4..7], $attr_string);
    # say "BB: $gene_record{$mRNA_ID_base}";
  }
}

# Process the GFF contents
my $comment_string = "";
my ($new_ID, $new_gene_ID, %seen_mRNA_base);
my $tcpt_ct = 0;
foreach my $line (@whole_gff) {
  if ($line =~ /(^#.+)/) { # print comment line 
    push @provisional_gff, $1;
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

    if ($fields[2] eq "gene"){ 
      $tcpt_ct = 0;
      $new_gene_ID = $id_mRNA_of_gene{$ID}; # should be mRNA_ID_base, stored in the first loop
      $seen_mRNA_base{$new_gene_ID}++;
      $gene_record{$new_gene_ID} = join("\t", @fields[0..7], "ID=$new_gene_ID;Name=$new_gene_ID;locus=$ID");
      $Parent = $new_gene_ID;
    }
    elsif ($fields[2] =~ /mRNA/){
      $tcpt_ct++;
      my $mRNA_ID_base = $ID;
      $mRNA_ID_base =~ s/$ID_REX/$1/;
      $seen_mRNA_base{$mRNA_ID_base}++;
      push @provisional_gff, join("\t", @fields[0..7], "ID=$ID;Name=$Name;Parent=$Parent");
    }
    else { # feature is something other than gene or mRNA
      push @provisional_gff, join("\t", @fields[0..7], $ninth);
    }
  }
}

# Print accumulated GFF -- gene records from a hash, and everything else from an array.
while ( my($k,$v) = each %gene_record ) {
  say $v;
}
foreach my $line (@provisional_gff) {
  say $line;
}


__END__

Steven Cannon
Versions
2024-01-14 New script. 
2024-01-16 For mRNA and transcript features that lack a gene record, generate one.

