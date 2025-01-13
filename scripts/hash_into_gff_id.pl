#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use feature "say";

my $usage = <<EOS;
  Synopsis: hash_into_gff_id.pl -gff GFF_FILE.gff3 -featid_map FILE.tsv [options] 
  
  Read a key-value hash file, and a GFF file (may be compressed or not).
  Swap the feature (gene) IDs with the values from a gene hash file, if provided.
  Swap the seqIDs (column 1) with the values from a seqid hash file, if provided.
  Optionally, exclude records for features in a provided list of feature IDs.
  This script will apply a positional sorting method if -sort is specified.
  
  Required:
    -gff_file     GFF file; may be compressed or not.
  ... and at least one of -featid_map and -seqid_map
    -featid_map  Key-value hash filename, where first column has gene IDs from GFF file.
    -seqid_map   Key-value hash filename, where first column has seqIDs from GFF file.
       
  Options:
    -suppress    File with list of components (mRNAs, CDSs, exons) or genes to exclude.
                   To exclude a component, use a splice suffix (GENE_A.1). To also
                   exclude a gene record, use the bare gene name (GENE_A)
    -sort        (boolean) Sort the GFF file. This attempts to put child features below parents.
    -out_file    File to write to; otherwise, to stdout.
    -strip_regex (string) Quoted regular expression to remove from ID to produce Name, e.g.
                           "gensp.Accn.gnm1.ann1." 
    -help        (boolean) This message.
EOS

my ($gff_file, $featid_map, $seqid_map, $suppress, $sort, $out_file, $strip_regex, $help, $STR_RX);

GetOptions (
  "gff_file=s" =>    \$gff_file,   # required
  "featid_map:s" =>  \$featid_map,   
  "seqid_map:s" =>   \$seqid_map,  
  "out_file:s" =>    \$out_file,   
  "suppress:s" =>    \$suppress,   
  "sort" =>          \$sort,
  "strip_regex:s" => \$strip_regex,
  "help" =>          \$help,
);

die "$usage" unless ((defined($featid_map) || defined($seqid_map)) && defined($gff_file));
die "$usage" if ($help);

if ( $strip_regex ){ 
  #say "strip_regex: $strip_regex";
  $STR_RX=qr/$strip_regex/;
  #say ":STR_RX: $STR_RX";
}

# Read in hash of gene IDs
my %featid_map;
if ($featid_map) {
  open(my $GNHSH, '<', $featid_map) or die "can't open in featid_map, $featid_map: $!";
  while (<$GNHSH>) {
    chomp;
    /(\S+)\s+(.+)/;
    my ($id, $featid_map_val) = ($1,$2);
    $featid_map{$id} = $featid_map_val;   
    # say "$id, $featid_map{$id}";
  }
}

# Read in hash of seqIDs
my %seqid_map;
if ($seqid_map) {
  open(my $SEQHSH, '<', $seqid_map) or die "can't open in seqid_map, $seqid_map: $!";
  while (<$SEQHSH>) {
    chomp;
    /(\S+)\s+(.+)/;
    my ($id, $seqid_map_val) = ($1,$2);
    $seqid_map{$id} = $seqid_map_val;   
    # say"$id, $seqid_map{$id}";
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
    #say "$_";
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
  open ($GFF_FH, "zcat $gff_file|") or die "Can't do zcat $gff_file|: $!";
}
else {
  open ( $GFF_FH, "<", $gff_file ) or die "Can't open in $gff_file: $!\n";
}

# Sorting method by Sam Hokin & S. Cannon. Standalone script: sort_gff.pl
my @gff_lines;
my %type_collate = (
  region => 10,
  scaffold => 20,
  contig => 30,
  gene => 40,
  pseudogene => 50,
  transposable_element_gene => 60,
  mRNA => 70,
  transcript => 80,
  ncRNA => 90,
  lnc_RNA => 100,
  snoRNA => 110,
  snRNA => 120,
  rRNA => 130,
  tRNA => 140,
  exon => 150,
  three_prime_UTR => 160,
  CDS => 170,
  five_prime_UTR => 180,
  protein_match => 190,
  cDNA_match => 200,
  match => 210,
  match_part => 220,
  expressed_sequence_match => 230,
  translated_nucleotide_match => 240,
);

my $last_collate_number = 10*(keys %type_collate);

while (<$GFF_FH>) {
  s/\r?\n\z//; # CRLF to LF
  chomp;
  my $line = $_;
  next if ($line =~ /^\s*$/);
  if ( $line =~ /^###$/ ) { next } # Skip spacer lines
  if ( $line =~ /^#.+/ ) { # print comment line 
    say $OUT_FH $line;
  }
  else { # body of the GFF
    my @parts = split(/\t/, $line);
    if (scalar(@parts)<9){ next }
    if ($strip_regex){
      $line =~ s/$STR_RX//g;
    }
    push(@gff_lines, $line);
    
    my $type = $parts[2];
    unless ($type_collate{$type}){
      $last_collate_number += 10;
      $type_collate{$type} = $last_collate_number;
    }
  }
}

my @split_lines = map {my @a = split /\t/; \@a;} @gff_lines;

if ($sort) { # Sorting method by Sam Hokin
  @split_lines = sort {
    $a->[0] cmp $b->[0] || $a->[3] <=> $b->[3] || $type_collate{$a->[2]} <=> $type_collate{$b->[2]}
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

  if ($seqid_map){
    my $seqid = $fields[0];
    $fields[0] = $seqid_map{$seqid};

    if (!$featid_map){ # No featid_map, so just print after swapping the sequid
      say $OUT_FH join("\t", @fields[0..8]);
      next;
    }
  }
  
  next if (scalar(@fields)<9);
  my $col9 = $fields[8];
  my @col9_attrs = split(/;/, $col9);
  my @new_attrs;
  my $old_ID;
  #say "$fields[2]\t", join("\t",@col9_attrs);
  for my $attr (@col9_attrs){
    if ($attr =~ /Parent=(.+)/){
      my @parents_ary = split(/,/, $1);
      my @new_parents_ary;
      for my $parent (@parents_ary){
        my $new_parent;
        if (defined $featid_map{$parent}){
          $new_parent = $featid_map{$parent};
        }
        else {
          warn "No map item found for $parent.\n";
          $new_parent = $parent;
        }
        unless ($suppress_hsh{$parent}){
          push @new_parents_ary, $new_parent;
        }
      }
      my $new_parents_str="Parent=" . join(",", @new_parents_ary);
      push @new_attrs, $new_parents_str;
    }
    elsif ($attr =~ /ID=([^;]+)/){
      $old_ID = $1;
      #say "old_ID: [$old_ID]";
      my $new_ID_str;
      if (defined $featid_map{$old_ID}){
        $new_ID_str = "ID=$featid_map{$old_ID}";
      }
      else {
        warn "No map item found for $old_ID.\n";
        $new_ID_str = "ID=$old_ID"
      }
      push @new_attrs, $new_ID_str;
    }
    elsif ($attr =~ /Name=([^;]+)/){
      # Use $old_ID from ID=() above. This assumes Name follows ID
      my $new_Name_str;
      if (defined $featid_map{$old_ID}){
        $new_Name_str = "Name=$featid_map{$old_ID}";
      }
      else {
        warn "No map item found for $old_ID.\n";
        $new_Name_str = "Name=$old_ID";
      } 
      if ($strip_regex){ # Strip from ID to produce Name
        $new_Name_str =~ s/$STR_RX//g;
      }
      push @new_attrs, $new_Name_str;
    }
    else { # Some other attribute
      push @new_attrs, $attr;
    }
  }
  say $OUT_FH join("\t", @fields[0..7]), "\t", join(";", @new_attrs);
}

__END__

Steven Cannon
2014-05-22 New script. Appears to work.
2017-01-10 Handle commented lines in GFF (the header)
2018-02-09 Add more flexibility in printing commented lines (e.g. interspersed comments)
2018-09-17 Handle features with multiple parents (an exon or CDS can be a part of multiple mRNAs)
 Also remove option for taking in regex for stripping suffix such as "-mRNA-"
   because this can now be replaced afterwards with e.g. perl -pi -e 's/-mRNA-/./g'
 Also take in a list of features to suppress (genes and/or splice variants)
2022-08-11 Add option to swap seqIDs (col 1) with a provided hash. 
 Also handle GFFs with CRLF line returns.
2022-10-04 Take GFF in via STDIN, to allow streaming from zipped file
2022-10-11 Take GFF file as parameter, handling compressed and uncompressed files.
            Print to named file or to STDOUT.
            Add sorting routine.
2022-11-13 Simplify name to ds_souchef.pl .
           Rework hashing of attributes (ID, Parent, Name). Recover positional sortring routine, after briefly removing it.
2022-12-10 Permit hashing of EITHER seqid or featid 
2023-03-03 Add some feature types for collate sort
2023-07-05 Print old attribute name if no hash replacement is found.
2023-07-08 Print warning if no hash replacement is found. Fix collate sort by using floats to order them.
2024-02-05 Update sorting method, now handling arbitrary types (col 3), adding nonstandard ones to the end of the type_collate hash.
2025-01-13 Switch to zcat from gzcat.
