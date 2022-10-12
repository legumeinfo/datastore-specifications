#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use IO::Zlib;
use feature "say";

my $usage = <<EOS;
  Synopsis: gzcat GFF_FILE.gff3.gz | hash_into_gff_id.pl [options] -seqid_hash
       OR     hash_into_gff_id.pl [options] -seqid_hash < GFF_FILE.gff3
  
  Read a key-value hash file, and a GFF file (may be compressed or not).
  Swap the feature (gene) IDs with the values from a gene hash file, if provided.
  Swap the seqIDs (column 1) with the values from a seqid hash file, if provided.
  Optionally, exclude records for features in a provided list of feature IDs.

  NOTE: The GFF input file should be structurally correct. It may not work correctly for a
  non-sorted GFF. Patch the GFF first if needed, e.g. with agat_convert_sp_gxf2gxf.pl
  This script will apply a quick-and-dirty sorting method -sort is specified.
  
  Required:
    -gff_file    GFF file; may be compressed or not.
    -gene_hash   (string) Key-value hash filename, where first column has gene IDs from GFF file.

  Options:
    -seqid_hash  (string) Key-value hash filename, where first column has seqIDs from GFF file.
    -suppress    (string) File with list of components (mRNAs, CDSs, exons) or genes to exclude.
                   To exclude a component, use a splice suffix (GENE_A.1). To also
                   exclude a gene record, use the bare gene name (GENE_A)
    -sort        (boolean) Sort the GFF file. This attempts to put child features below parents.
    -out_file    (string) write to this file; otherwise, to stdout.
    -strip_regex (string) Regular expression for removing a pattern from the GFF, prior to hashing.
    -help        (boolean) This message.
EOS

my ($gff_file, $gene_hash, $seqid_hash, $suppress, $sort, $out_file, $strip_regex, $help, $STR_RX);

GetOptions (
  "gff_file=s" =>    \$gff_file,   # required
  "gene_hash=s" =>   \$gene_hash,   # required
  "seqid_hash:s" =>  \$seqid_hash,  
  "out_file:s" =>    \$out_file,   
  "suppress:s" =>    \$suppress,   
  "sort" =>          \$sort,
  "strip_regex:s" =>   \$strip_regex,
  "help" =>          \$help,
);

die "$usage" unless (defined($gene_hash) && defined($gff_file));
die "$usage" if ($help);

if ( $strip_regex ){ 
  #say "strip_regex: $strip_regex";
  $STR_RX=qr/$strip_regex/;
  #say ":STR_RX: $STR_RX";
}

# Read in hash of gene IDs
my %gene_hash;
if ($gene_hash) {
  open(my $GNHSH, '<', $gene_hash) or die "can't open in gene_hash, $gene_hash: $!";
  while (<$GNHSH>) {
    chomp;
    /(\S+)\s+(.+)/;
    my ($id, $gene_hash_val) = ($1,$2);
    $gene_hash{$id} = $gene_hash_val;   
    # print "$id, $gene_hash{$id}\n";
  }
}

# Read in hash of seqIDs
my %seqid_hash;
if ($seqid_hash) {
  open(my $SEQHSH, '<', $seqid_hash) or die "can't open in seqid_hash, $seqid_hash: $!";
  while (<$SEQHSH>) {
    chomp;
    /(\S+)\s+(.+)/;
    my ($id, $seqid_hash_val) = ($1,$2);
    $seqid_hash{$id} = $seqid_hash_val;   
    # print "$id, $seqid_hash{$id}\n";
  }
}

# Read in list of genes and splice variants to suppress, if provided
my %suppress_hsh;
if (defined($suppress)) {
  open(my $SUP, '<', $suppress) or die "can't open in suppress, $suppress: $!";
  while (<$SUP>) {
    chomp;
    next if /^$/;
    $suppress_hsh{$_}++;
    #print "$_\n";
  }
}

my $OUT_FH;
if ( $out_file ){
  open ( $OUT_FH, ">", $out_file ) or die "Can't open out $out_file: $!\n";
}
else {
  open ( $OUT_FH, ">&", \*STDOUT) or die;
}

# Read in the GFF;
my $GFF_FH;
if ( $gff_file =~ /gz$/ ) {
  $GFF_FH = new IO::Zlib;
  $GFF_FH->open($gff_file, "rb");
}
else {
  open ( $GFF_FH, "<", $gff_file ) or die "Can't open in $gff_file: $!\n";
}

# Sorting method by Sam Hokin. Standalone script: sort_gff.pl
my $comment_string = "";
my @gff_lines;
my %type_collate = (
  gene => 0,
  mRNA => 1,
  ncRNA => 1.5,
  rRNA => 1.75,
  tRNA => 1.875,
  exon => 2,
  three_prime_UTR => 3,
  CDS => 4,
  five_prime_UTR => 5,
  protein_match => 6,
  match_part => 7,
);

while (<$GFF_FH>) {
  s/\r?\n\z//; # CRLF to LF
  chomp;
  my $line = $_;
  if ( $line =~ /(^#.+)/ ) { # print comment line 
    $comment_string = "$1\n";
    print $OUT_FH "$comment_string";
  }
  else { # body of the GFF
    if ($strip_regex){
      $line =~ s/$STR_RX//g;
    }
    push(@gff_lines, $line);
  }
}

my @split_lines = map {my @a = split /\t/; \@a;} @gff_lines;
if ($sort) { # Sorting method by Sam Hokin
  @split_lines = sort {
    $a->[0] cmp $b->[0] || $a->[3] <=> $b->[3] || $type_collate{$a->[2]} cmp $type_collate{$b->[2]}
  } @split_lines;
}
else { 
  #nothing; we'll use the provided sorting.
}

my ($gene_name, $new_gene_id);

# Process body of the GFF. Comments were printed earlier.
for my $split_line (@split_lines){
  my @fields = @$split_line; # Renaming for clarity; @fields has the 9 GFF elements for this line.
  #say join("\t", @fields);

  if ($seqid_hash){
    my $seqid = $fields[0];
    $fields[0] = $seqid_hash{$seqid};
  }
  
  my $col9 = $fields[8];
  my @col9_k_v = split(/;/, $col9);
  my $col3 = $fields[2];
  my $attr_ct = 0;
  #print $fields[4]-$fields[3], "\t", $fields[2], "\t";
  if ( $col3 =~ /gene/i ) {
    $gene_name = $col9;
    $gene_name =~ s/ID=([^;]+);.+/$1/;
    if ($gene_hash) {
      $new_gene_id = $gene_hash{$gene_name};
    }
    #print "GENE:$gene_name\t$new_gene_id\t";
    #print "[$col9]\n";
    if ( $suppress_hsh{$gene_name} ) { 
      # skip; do nothing
    }
    else {
      print $OUT_FH join("\t", @fields[0..7]);
      print $OUT_FH "\t";
      if ($gene_hash) {
        $col9 =~ s/$gene_name/$new_gene_id/g;
      }
      else {
        # Do nothing, since we don't have a $gene_hash 
      }
      print $OUT_FH "$col9;";
      print $OUT_FH "\n";
    }
  }
  else { # one of the gene components: CDS, mRNA etc.
    my $part_name = $col9;
    $part_name =~ s/ID=([^;]+);.+/$1/;
    $part_name =~ s/([^:]+):.+/$1/;
    #print "PART:$part_name\t";
    #print "{$col9}\n";

    if ($suppress_hsh{$part_name}) {
      # skip; do nothing
    }
    else {
      print $OUT_FH join("\t", @fields[0..7]);
      print $OUT_FH "\t";

      # Split parents into an array
      my $parents = $col9;
      $parents =~ s/.+;Parent=(.+)/$1/i;
      my @parents_ary = split(/,/, $parents);
      #print join("=====", @parents_ary), "\n";

      foreach my $parent (@parents_ary) {
        if ( $suppress_hsh{$parent} ) { # strip this parent from list of parents
          $col9 =~ s/$parent//g;
          $col9 =~ s/,,/,/g;
          if (length($col9)<10) {
            warn "WARNING: Check elements related to $part_name. The 9th field is suspiciously short. " .
              "All parents may have been removed.\n"
            }
        }
        else {
          # do nothing (don't remove parent from string) because it's OK.
        }
      }
      $col9 =~ s/$gene_name/$new_gene_id/g;
      print $OUT_FH "$col9;";
      print $OUT_FH "\n";
    }
  }
}


__END__

Steven Cannon
Versions
v01 2014-05-22 New script. Appears to work.
v02 2017-01-10 Handle commented lines in GFF (the header)
v03 2018-02-09 Add more flexibility in printing commented lines (e.g. interspersed comments)
v04 2018-09-17 Handle features with multiple parents (an exon or CDS can be a part of multiple mRNAs)
     Also remove option for taking in regex for stripping suffix such as "-mRNA-"
       because this can now be replaced afterwards with e.g. perl -pi -e 's/-mRNA-/./g'
     Also take in a list of features to suppress (genes and/or splice variants)
v05 2022-08-11 Add option to swap seqIDs (col 1) with a provided hash. 
     Also handle GFFs with CRLF line returns.
v06 2022-10-04 Take GFF in via STDIN, to allow streaming from zipped file
v07 2022-10-11 Take GFF file as parameter, handling compressed and uncompressed files.
                Print to named file or to STDOUT.
                Add sorting routine.

Tests:
test2.gff3
  We want to suppress maker-Arahy.17-snap-gene-43.4-mRNA-1 :
    grep Arahy.17-snap-gene-43.4 lis.short_mRNAs_and_genes_to_remove 
  This should leave six rows in the output:
    grep -v "maker-Arahy.17-snap-gene-43.4-mRNA-1" test2.gff3 | cut -f3,9
      gene	ID=maker-Arahy.17-snap-gene-43.4;Name=maker-Arahy.17-snap-gene-43.4
      mRNA	ID=maker-Arahy.17-snap-gene-43.4-mRNA-2;Parent=maker-Arahy.17-snap-gene-43.4;Name=maker-Arahy.17-snap-gene-43.4-mRNA-2;_AED=0.35;_eAED=0.35;_QI=429|0|1|1|0|1|2|139|32
      three_prime_UTR	ID=maker-Arahy.17-snap-gene-43.4-mRNA-2:three_prime_utr;Parent=maker-Arahy.17-snap-gene-43.4-mRNA-2
      exon	ID=maker-Arahy.17-snap-gene-43.4-mRNA-2:exon:10142;Parent=maker-Arahy.17-snap-gene-43.4-mRNA-2
      CDS	ID=maker-Arahy.17-snap-gene-43.4-mRNA-2:cds;Parent=maker-Arahy.17-snap-gene-43.4-mRNA-2
      five_prime_UTR	ID=maker-Arahy.17-snap-gene-43.4-mRNA-2:five_prime_utr;Parent=maker-Arahy.17-snap-gene-43.4-mRNA-2
      five_prime_UTR	ID=maker-Arahy.17-snap-gene-43.4-mRNA-2:five_prime_utr;Parent=maker-Arahy.17-snap-gene-43.4-mRNA-2


