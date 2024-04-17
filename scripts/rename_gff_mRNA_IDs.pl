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

    -outfile   (string) Output file for gff; otherwise, to STDOUT
    -restfile  (string) Output file for features excluded from -out

  Options:
    -ID_regex  (string) Pattern for the base ID, to capture the portion preceeding e.g. .1 .mRNA.1 
                        Default: '(\\w+)\\.\\d+\$'
    -xclude    (string) List of features to exclude from output; comma-separated, e.g. "lnc_RNA,pseudogene,tRNA"
    -verbose   (boolean) Report removed features to STDOUT. Best to specify -out if -verbose is indicated.
    -help      (boolean) This message.
EOS

my ($help, $xclude, $verbose, $outfile, $restfile);
my $ID_regex = '(\w+)\.\d+$';
my $splice_regex = '.+\.(\d+)$';

GetOptions (
  "ID_regex:s" => \$ID_regex,
  "xclude:s" =>   \$xclude,
  "outfile:s" =>  \$outfile,
  "restfile:s" => \$restfile,
  "verbose" =>    \$verbose,
  "help" =>       \$help,
);

die "$usage" if ($help);

my $ID_REX = qr/$ID_regex/;
my $SP_REX = qr/$splice_regex/;

my ($OUTFH, $RESTFH);
if ($outfile){ open ($OUTFH, ">", $outfile) or die "Can't open out $outfile: $!\n" }
if ($restfile){ open ($RESTFH, ">", $restfile) or die "Can't open out $restfile: $!\n" }
unless ($outfile){ die "Please specify -out and a filename for retained GFF features\n" }
unless ($restfile){ die "Please specify -rest and a filename for excluded GFF features\n" }

my @xclude_ary;
if ($xclude){ @xclude_ary = split(/,/, $xclude) }

# Read the GFF contents. Store for later use, and remember ID :: Name pairs for mRNA features
my (%id_mRNA_of_gene, %id_of_feat_to_xclude, @whole_gff, %gene_record);
while (<STDIN>) {
  s/\r?\n\z//; # CRLF to LF
  chomp;
  push(@whole_gff, $_);
  next if ($_ =~ /^#/);

  my @fields = split(/\t/, $_);
  my $type = $fields[2];
  my @attrs = split(/;/, $fields[8]);
  if ($fields[8] =~ /Parent=/){ # should be mRNA and similar features directly below gene.
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

    if ( grep(/$type/, @xclude_ary) || $type =~ /pseudogene/ ){
      $id_of_feat_to_xclude{$Parent} = $mRNA_ID_base;
      # say "XX: type=$type\tID=$ID\tmRNA_ID_base=$mRNA_ID_base\tParent=$Parent\t" .
      #     "id_of_feat_to_xclude=$id_of_feat_to_xclude{$Parent}";
    }
    else {
      $id_mRNA_of_gene{$Parent} = $mRNA_ID_base;
      # say "AA: ID=$ID\tmRNA_ID_base=$mRNA_ID_base\tParent=$Parent\tid_mRNA_of_gene=$id_mRNA_of_gene{$Parent}";
    }

    # Make a gene record for this feature, to be used only if the GFF has none.
    my $attr_string = "ID=$mRNA_ID_base;Name=$mRNA_ID_base;locus=$ID";
    $gene_record{$mRNA_ID_base} = join("\t", @fields[0..1], "gene", @fields[4..7], $attr_string);
    # say "BB: $gene_record{$mRNA_ID_base}";
  }
}

# Process the GFF contents
my $comment_string = "";
my ($new_ID, $new_gene_ID, %seen_mRNA_base);
my (%seen_feat_to_skip, %seen_lnc_RNA, %seen_pseudogene, %seen_transcript, %seen_out_line, %seen_rest_line);
my $tcpt_ct = 0;
my ($mRNA_ID_base, $new_mRNA_ID);
foreach my $line (@whole_gff) {
  if ($line =~ /^#.+/) { # print comment line
    &printstr($OUTFH, $line );

    # Also print comment line to the restfile here, since %seen_rest_line prevents second printing via printstr
    unless ($seen_rest_line{$line}) {
      $seen_rest_line{$line}++;
      say $RESTFH $line;
    }
  }
  else { # body of the GFF
    my @fields = split(/\t/, $line);

    my $type = $fields[2];
    my $ninth = $fields[8];
    my @attrs = split(/;/, $ninth);
    my ($ID, $Name, $Parent);
    foreach my $attr (@attrs){
      my ($k, $v) = split(/=/, $attr);
      if ($k =~ /\bID/){ $ID = $v }
      elsif ($k =~ /\bName/){ $Name = $v }
      elsif ($k =~ /\bParent/){ $Parent = $v }
    }

    foreach my $skip_ID (keys %id_of_feat_to_xclude) {
      if ($line =~ /$skip_ID/){ # Exclude these and their sub-features
        $seen_feat_to_skip{$ID}++;
        next;
      }
    }
    
    if ($line =~ /cDNA_match/){ # In GenBank GFFs, these lack proper gene structure. Skip.
      &printstr($RESTFH, join("\t", @fields[0..8]) );
      next;
    }
    
    if ($type eq "pseudogene"){ # These lack mRNA records. Exclude them and their sub-features (exons).
      &printstr($RESTFH, join("\t", @fields[0..8]) );
      $seen_pseudogene{$ID}++;
      next;
    }
    
    if ($type eq "lnc_RNA"){ # These lack mRNA records. Exclude them and their sub-features (exons).
      &printstr($RESTFH, join("\t", @fields[0..8]) );
      $seen_lnc_RNA{$ID}++;
      next;
    }
    
    if ($type eq "transcript"){ # These are redundant with mRNA records. Exclude them and their sub-features (exons).
      &printstr($RESTFH, join("\t", @fields[0..8]) );
      $seen_transcript{$ID}++;
      next;
    }

    if ($seen_feat_to_skip{$ID}){
      &printstr($RESTFH, join("\t", @fields[0..8]) );
      next;
    }
    else {
      my $mRNA_ID;
      if ($type eq "gene" | $type eq "region"){
        $tcpt_ct = 0;
        &printstr($OUTFH, join("\t", @fields[0..8]) );
      }
      elsif ($type =~ /mRNA|transcript|lnc_RNA|snoRNA|snRNA|tRNA|rRNA/) {
        $tcpt_ct++;
        $mRNA_ID = $ID;
        $mRNA_ID_base = $ID;
        $mRNA_ID_base =~ s/$ID_REX/$1/;
        $seen_mRNA_base{$mRNA_ID_base}++;
        $new_mRNA_ID = "$Parent.$tcpt_ct";
        &printstr($OUTFH, join("\t", @fields[0..7], "ID=$new_mRNA_ID;Name=$new_mRNA_ID;Parent=$Parent") );
      }
      elsif ($type =~ /exon/) {
        if ( $seen_pseudogene{$Parent} || $seen_lnc_RNA{$Parent} || $seen_transcript{$Parent} ){
          next;
        }
        if ($verbose){ say "SS: [$ID] <$Parent> {$new_mRNA_ID}" }
        $ID =~ /(exon)-(.+)\.\d+-(\d+)$/;
        my $new_ID = "$1-$new_mRNA_ID-$3";
        my $exon_Parent = "$new_mRNA_ID";
        &printstr($OUTFH, join("\t", @fields[0..7], "ID=$new_ID;Name=$new_ID;Parent=$exon_Parent") );
      }
      elsif ($type =~ /CDS/) {
        $ID =~ /.+\.\d+-(\d+)$/;
        my $new_ID = "$new_mRNA_ID-$1";
        my $cds_Parent = "$new_mRNA_ID";
        &printstr($OUTFH, join("\t", @fields[0..7], "ID=$new_ID;Name=$cds_Parent;Parent=$cds_Parent") );
      }
      else {
        $ID =~ /(.+)\.\d+-(\d+)$/;
        warn "ZZ: Unexpected type: ", join("\t", @fields[0..8]), "\n";
      }
    }
  }
}

#####################
sub printstr {
  my $FH = shift;
  my $str_to_print = join("", @_);
  if ($seen_out_line{$str_to_print}){
    warn "SS: Duplicate line: [$str_to_print]\n";
    return
  } else {
    $seen_out_line{$str_to_print}++;
    say $FH $str_to_print;
  }
}

__END__

Steven Cannon
Versions
2024-01-16 New script.
2024-03-25 Handle list of feature types to exclude
2024-03-26 Warn of duplicate output lines
2024-03-27 Handle superfulous transcripts and lnc_RNA
2024-04-07 Some variable renaming for consistency, and progress output to stdout
2024-04-17 Print excluded features to -restfile FILENAME

