#!/usr/bin/env perl

use warnings;
use strict;
use YAML::Tiny 'LoadFile';
use Getopt::Long;
use Data::Dumper;
use IO::Zlib;
use File::Copy;
use feature "say";

my $usage = <<EOS;
  Synopsis: prep_genomic_collection.pl -config CONFIG.yml

  This script uses information in a yaml-format config file to prepare data store 
  collections for genomic data, comprising genome assemblies and/or gene annotations. 
  The script also writes the associated metadata for the collections, including 
  the README and MANIFEST files. Not all fields are populated in the README, however. 
  So, check and manually edit the README files to complete them. 

  Required:
    -config  yaml-format file with information for the metadata and the file conversions.
  Options:
    -chr_hash  Full, absolute path to file with hash with old/new chromosome & scaffold IDs.
                  Will be calculated unless specified here.
    -gene_hash Full, absolute path to file with hash with old/new gene IDs (excluding splice variant).
                  Will be calculated unless specified here.
    -help      (boolean) This message.
EOS

my ($config, $chr_hash, $gene_hash, $help); 

GetOptions (
  "config=s" =>    \$config,  # required
  "chr_hash:s" =>  \$chr_hash,
  "gene_hash:s" => \$gene_hash,
  "help" =>        \$help,
);

die "$usage" unless (defined($config));
die "$usage" if ($help);

if ($chr_hash){
  unless ( -e $chr_hash ){ die "Chromosome hash file not found at $chr_hash.\n" .
     "Please provide full path, or omit this flag to have the hash calculated.\n" }
}

if ($gene_hash){
  unless ( -e $gene_hash ){ die "Gene hash file not found at $chr_hash.\n" . 
    "Please provide full path, or omit this flag to have the hash calculated.\n" }
}

my $yaml = YAML::Tiny->read( $config );

my $confobj = LoadFile($config);
#print Dumper($confobj);

my %coll_hsh;
for (keys %{$confobj->{collection_info}}){ $coll_hsh{$_} = $confobj->{collection_info}->{$_} }

my %dir_hsh;
for (keys %{$confobj->{directories}}){ $dir_hsh{$_} = $confobj->{directories}->{$_} }

my %prefix_hsh;
for (keys %{$confobj->{prefixes}}){ $prefix_hsh{$_} = $confobj->{prefixes}->{$_} }

my %readme_hsh;
for (keys %{$confobj->{readme_info}}){ $readme_hsh{$_} = $confobj->{readme_info}->{$_} }

my $GNMCOL = "$coll_hsh{accession}.$coll_hsh{gnm_ver}.$coll_hsh{genome_key}";
my $ANNCOL = "$coll_hsh{accession}.$coll_hsh{gnm_ver}.$coll_hsh{ann_ver}.$coll_hsh{annot_key}";
my $GENSP = $coll_hsh{gensp};
my $TO_GNM_PREFIX = "$coll_hsh{gensp}.$coll_hsh{accession}.$coll_hsh{gnm_ver}";
my $TO_ANN_PREFIX = "$coll_hsh{gensp}.$coll_hsh{accession}.$coll_hsh{gnm_ver}.$coll_hsh{ann_ver}";

# Make collection directories
my $WD = "$dir_hsh{work_dir}";
my $ANNDIR = "$WD/annotations/$ANNCOL";
unless (-d $ANNDIR) {mkdir -p $ANNDIR or die "Can't make directory $ANNDIR: $!\n"}
my $GNMDIR = "$WD/annotations/$ANNCOL";
unless (-d $GNMDIR) {mkdir -p $GNMDIR or die "Can't make directory $GNMDIR: $!\n"}


##################################################
say "\n== Copying over \"as-is\" annotation information files, if present, unchanged ==";
for my $fr_to_hsh (@{$confobj->{from_to_as_is}}){ 
  my $AS_IS_FROM_FILE = "$WD/$dir_hsh{from_annot_dir}/$prefix_hsh{from_annot_prefix}.$fr_to_hsh->{from}";
  my $AS_IS_TO_FILE = "$ANNDIR/$GENSP.$ANNCOL.$fr_to_hsh->{to}";
  say "Copying from-to as-is annotation files:";
  say "  $AS_IS_FROM_FILE"; 
  say "  $ANNDIR/$GENSP.$ANNCOL.$fr_to_hsh->{to}\n";
  if ($AS_IS_FROM_FILE =~ /gz$/){
    my $AS_IS_FROM_FH = new IO::Zlib;
    $AS_IS_FROM_FH->open($AS_IS_FROM_FILE, "rb");
    open (my $AS_IS_TO_FH, ">", $AS_IS_TO_FILE) or die "Can't open out $AS_IS_TO_FILE: $!\n";
    while (<$AS_IS_FROM_FH>) {
      print $AS_IS_TO_FH $_;
    }
  }
  else { # File isn't gzipped
    copy("$WD/$dir_hsh{from_annot_dir}/$prefix_hsh{from_annot_prefix}.$fr_to_hsh->{from}", 
      "$ANNDIR/$GENSP.$ANNCOL.$fr_to_hsh->{to}");
  }
}

##################################################
say "\n== Making a hash of old/new chromosome and scaffold IDs, to go to the genomes directory ==";

# Get path to main genome assembly input file, and regex for chromosomes and scaffolds
my $GENOME_FILE_START;
for my $fr_to_hsh (@{$confobj->{from_to_genome}}){ 
  if ($fr_to_hsh->{to} =~ /genome_main/){
    $GENOME_FILE_START = 
      "$dir_hsh{work_dir}/$dir_hsh{from_genome_dir}/$prefix_hsh{from_genome_prefix}.$fr_to_hsh->{from}";
  }
}
say $GENOME_FILE_START;
unless (-e $GENOME_FILE_START) {
  die "File $GENOME_FILE_START doesn't exist. Check filename components in config file.\n"
}

my $CHR_HASH;
if ($chr_hash){ 
  say "Hash of old/new chromosome & scaffold IDs has been provided:\n  $chr_hash";
  $CHR_HASH = $chr_hash;
}
else { 
  $CHR_HASH = "$WD/genomes/$GNMCOL/$GENSP.$GNMCOL.chr_name_hash.tsv";
  open (my $CHR_HASH_FH, ">", $CHR_HASH) or die "Can't open out $CHR_HASH: $!\n";
  say "Generating hash of old/new chromosome & scaffold IDs.";
  my $GNM_MAIN_FH = new IO::Zlib;
  $GNM_MAIN_FH->open($GENOME_FILE_START, "rb");
  while (my $line = <$GNM_MAIN_FH>){
    if ($line =~ /^>(\S+)/){
      my $chr = $1;
      say "$chr\t$TO_GNM_PREFIX.$chr";
      say $CHR_HASH_FH "$chr\t$TO_GNM_PREFIX.$chr";
    }
  }
}

##################################################
say "\n== Making a hash of old/new gene IDs, to go to the annotations directory ==";
say "   These are for the base gene IDs, without splice variant.";

# Get path to main CDS input file, and regex for splice variant on genes
my $CDS_FILE_START;
my $SPLICE_RX;
for my $fr_to_hsh (@{$confobj->{from_to_cds_mrna}}){ 
  if ($fr_to_hsh->{to} =~ /cds.fna/){
    $CDS_FILE_START = 
      "$dir_hsh{work_dir}/$dir_hsh{from_annot_dir}/$prefix_hsh{from_annot_prefix}.$fr_to_hsh->{from}";
    $SPLICE_RX = qr/$fr_to_hsh->{splice}/;
    say $SPLICE_RX;
  }
}
say $CDS_FILE_START;
unless (-e $CDS_FILE_START) {
  die "File $CDS_FILE_START doesn't exist. Check filename components in config file.\n"
}

my $GENE_HASH;
if ($gene_hash){ 
  say "Hash of old/new gene IDs has been provided:\n  $gene_hash";
  $GENE_HASH = $gene_hash;
}
else {
  say "Generating hash of old/new gene IDs.";
  my $CDS_IN_FH = new IO::Zlib;
  $CDS_IN_FH->open($CDS_FILE_START, "rb");
  $GENE_HASH = "$WD/annotations/$ANNCOL/$GENSP.$ANNCOL.gene_name_hash.tsv";
  open (my $GENE_HASH_FH, ">", $GENE_HASH) or die "Can't open out $GENE_HASH: $!\n";
  my %seen_gene_id;
  while (my $line = <$CDS_IN_FH>){
    if ($line =~ /^>(\S+)/){
      my $gene_id = $1;
      $gene_id =~ s/(.+)$SPLICE_RX/$1/;
      unless ( $seen_gene_id{$gene_id} ) {
        $seen_gene_id{$gene_id}++;
        say $GENE_HASH_FH "$gene_id\t$TO_ANN_PREFIX.$gene_id";
      }
    }
  }
}

##################################################
say "\n== Processing the nucleotide sequence files ==";
for my $fr_to_hsh (@{$confobj->{from_to_cds_mrna}}){ 
  my $SEQ_FROM_FILE = "$WD/$dir_hsh{from_annot_dir}/$prefix_hsh{from_annot_prefix}.$fr_to_hsh->{from}"; 
  my $SEQ_TO_FILE = "$ANNDIR/$GENSP.$ANNCOL.$fr_to_hsh->{to}";
  say "Converting from to:";
  say "  $SEQ_FROM_FILE";
  say "  $SEQ_TO_FILE";
  my $SPLICE_RX = $fr_to_hsh->{splice};
  $SPLICE_RX =~ s/\"//g; # Strip surrounding quotes if any. We'll add them below.
  say "  SPLICE REGEX: \"$SPLICE_RX\"";
  my $ARGS = "-hash $GENE_HASH -fasta $SEQ_FROM_FILE -splice \"$SPLICE_RX\" -nodef -out $SEQ_TO_FILE";
  #say "hash_into_fasta_id.pl $ARGS\n";
  system("hash_into_fasta_id.pl $ARGS");
}

##################################################
say "\n== Processing the protein sequence files ==";
for my $fr_to_hsh (@{$confobj->{from_to_protein}}){ 
  my $SEQ_FROM_FILE = "$WD/$dir_hsh{from_annot_dir}/$prefix_hsh{from_annot_prefix}.$fr_to_hsh->{from}"; 
  my $SEQ_TO_FILE = "$ANNDIR/$GENSP.$ANNCOL.$fr_to_hsh->{to}";
  say "Converting from to:";
  say "  $SEQ_FROM_FILE";
  say "  $SEQ_TO_FILE";
  my $SPLICE_RX = $fr_to_hsh->{splice};
  $SPLICE_RX =~ s/\"//g; # Strip surrounding quotes if any. We'll add them below.
  my $STRIP_RX = $fr_to_hsh->{strip};
  $STRIP_RX =~ s/\"//g; # Strip surrounding quotes if any. We'll add them below.
  say "  SPLICE REGEX: \"$SPLICE_RX\"";
  say "  STRIP REGEX: \"$STRIP_RX\"";
  my $ARGS = "-hash $GENE_HASH -fasta $SEQ_FROM_FILE -splice \"$SPLICE_RX\" -strip \"$STRIP_RX\" -nodef -out $SEQ_TO_FILE";
  #say "hash_into_fasta_id.pl $ARGS\n";
  system("hash_into_fasta_id.pl $ARGS");
}

##################################################
say "\n== Processing the GFF files ==";
for my $fr_to_hsh (@{$confobj->{from_to_gff}}){ 
  my $GFF_FROM_FILE = "$WD/$dir_hsh{from_annot_dir}/$prefix_hsh{from_annot_prefix}.$fr_to_hsh->{from}"; 
  my $GFF_TO_FILE = "$ANNDIR/$GENSP.$ANNCOL.$fr_to_hsh->{to}";
  say "Converting from to:";
  say "  $GFF_FROM_FILE";
  say "  $GFF_TO_FILE";
  my $STRIP_RX = $fr_to_hsh->{strip};
  $STRIP_RX =~ s/\"//g; # Strip surrounding quotes if any. We'll add them below.
  say "  STRIP REGEX: \"$STRIP_RX\"";
  my $ARGS = "-gff $GFF_FROM_FILE -gene_hash $GENE_HASH -seqid_hash $CHR_HASH -strip \"$STRIP_RX\" -sort -out $GFF_TO_FILE";
  #say "hash_into_fasta_id.pl $ARGS\n";
  system("hash_into_gff_id.pl $ARGS");
}

__END__

ANNCOLL=/usr/local/www/data/private/Glycine/max/GmaxWm82ISU_01/annotations/Wm82_ISU01.gnm2.ann1.FGFB
GENE_HASH_PATH=$ANNCOLL/glyma.Wm82_ISU01.gnm2.ann1.FGFB.gene_name_hash.tsv

GNMCOLL=/usr/local/www/data/private/Glycine/max/GmaxWm82ISU_01/genomes/Wm82_ISU01.gnm2.JFPQ
CHR_HASH_PATH=$GNMCOLL/glyma.Wm82_ISU01.gnm2.JFPQ.chr_name_hash.tsv

# Use existing chromosome and gene ID hashes:
./prep_genomic_collection.pl -chr_hash $CHR_HASH_PATH -gene_hash $GENE_HASH_PATH -config config_glyma*.yml

# Calculate chromosome and gene ID hashes (slow):
./prep_genomic_collection.pl -config config_glyma*.yml


# Test gene hashing
WD="/usr/local/www/data/private/Glycine/max/GmaxWm82ISU_01"
ANNCOLL=/usr/local/www/data/private/Glycine/max/GmaxWm82ISU_01/annotations/Wm82_ISU01.gnm2.ann1.FGFB
GENE_HASH_PATH=$ANNCOLL/glyma.Wm82_ISU01.gnm2.ann1.FGFB.gene_name_hash.tsv
OUT="$WD/annotations/Wm82_ISU01.gnm2.ann1.FGFB/glyma.Wm82_ISU01.gnm2.ann1.FGFB.cds.fna"
FASTA="/usr/local/www/data/private/Glycine/max/GmaxWm82ISU_01/v2.1/annotation/GmaxWm82ISU_01_724_v2.1.cds.fa.gz"

hash_into_fasta_id.pl -hash $GENE_HASH_PATH -fasta $FASTA -splice "\.\d+$" -nodef -out $OUT


