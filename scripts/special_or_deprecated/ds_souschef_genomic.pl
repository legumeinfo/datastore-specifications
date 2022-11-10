#!/usr/bin/env perl

use warnings;
use strict;
use YAML::Tiny 'LoadFile';
use Getopt::Long;
use File::Copy;
use File::Basename;
use feature "say";

my $usage = <<EOS;
  Synopsis: ds_souschef_genomic.pl -config CONFIG.yml

  This script uses information in a yaml-format config file to prepare data store 
  collections for genomic data, comprising genome assemblies and/or gene annotations. 
  The script also writes the associated metadata for the collections, including 
  the README and MANIFEST files. Check that all fields have been populated in the README.

  By default, all files will be converted (assemblies and annotation files).
  Particular types can be run separately (e.g. just the protein files or just assemblies),
  but note that the MANIFEST files will be overwritten and will include only the files
  of the specified type.

  Note that all input files are assumed to be in two directories, e.g. annotation and assembly
  (the names are specified in the config file). If there are release-policy or readme files
  that pertain to the assembly+annotation as a whole, first copy these into the 
  annotation and assembly directories. The program won't find them outside the specified directories.

  Required:
    -config    (string) yaml-format file with information for the metadata and the file conversions.
  Options:
    -chr_hash  (string) Full, absolute path to file with hash with old/new chromosome & scaffold IDs.
                  Will be calculated unless specified here.
    -gene_hash (string) Full, absolute path to file with hash with old/new gene IDs (excluding splice variant).
                  Will be calculated unless specified here.
    -all       (boolean) True by default, unless one or more of the modules below are specified.
  Set one or more of the following flags to run just those modules. If none are specified, "all" is implied.
    -readme    (boolean) Generate the README files. 
    -ann_as_is (boolean) Copy over the "as-is" annotation files (un-transformed).
    -gnm_as_is (boolean) Copy over the "as-is" genome files (un-transformed).
    -cds       (boolean) Process the CDS and mRNA files.
    -protein   (boolean) Process the protein files.
    -gff       (boolean) Process the GFF files.
    -assembly  (boolean) Process the genome assembly files.

    -extend    (boolean) Extend MANIFEST files from a previous run. Set this flag if you want to 
                 update the README or the CDS files without starting the MANIFESTs from scratch.

    -help      (boolean) This message.
EOS

my ($config, $chr_hash, $gene_hash, $help); 
my ($readme, $ann_as_is, $gnm_as_is, $cds, $protein, $gff, $assembly, $all, $extend);
my ($make_gene_hash, $make_chr_hash);

GetOptions (
  "config=s" =>    \$config,  # required
  "chr_hash:s" =>  \$chr_hash,
  "gene_hash:s" => \$gene_hash,
  "readme" =>      \$readme,
  "ann_as_is" =>   \$ann_as_is,
  "gnm_as_is" =>   \$gnm_as_is,
  "cds" =>         \$cds,
  "protein" =>     \$protein,
  "gff" =>         \$gff,
  "assembly" =>    \$assembly,
  "extend" =>      \$extend,
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

# All modules will be run unless flags are set for one or more of the particular modules.
$all++ unless ($readme || $ann_as_is || $gnm_as_is || $cds || $protein || $gff || $assembly);

my $yaml = YAML::Tiny->read( $config );

my $confobj = LoadFile($config);

my %coll_hsh;
for (keys %{$confobj->{collection_info}}){ $coll_hsh{$_} = $confobj->{collection_info}->{$_} }

my %dir_hsh;
for (keys %{$confobj->{directories}}){ $dir_hsh{$_} = $confobj->{directories}->{$_} }

my %prefix_hsh;
for (keys %{$confobj->{prefixes}}){ $prefix_hsh{$_} = $confobj->{prefixes}->{$_} }

my %readme_hsh;
for (keys %{$confobj->{readme_info}}){ $readme_hsh{$_} = $confobj->{readme_info}->{$_} }

# Make some variables for prefixes, for convenience
my $GNMCOL = "$coll_hsh{genotype}.$coll_hsh{gnm_ver}.$coll_hsh{genome_key}";
my $ANNCOL = "$coll_hsh{genotype}.$coll_hsh{gnm_ver}.$coll_hsh{ann_ver}.$coll_hsh{annot_key}";
my $GENSP = $coll_hsh{gensp};
my $scientific_name = "$coll_hsh{genus} $coll_hsh{species}";
my $TO_GNM_PREFIX = "$GENSP.$coll_hsh{genotype}.$coll_hsh{gnm_ver}";
my $TO_ANN_PREFIX = "$GENSP.$coll_hsh{genotype}.$coll_hsh{gnm_ver}.$coll_hsh{ann_ver}";

my $WD = "$dir_hsh{work_dir}";
my $ANNDIR = "$WD/annotations/$ANNCOL";
my $GNMDIR = "$WD/genomes/$GNMCOL";

my $ANN_MAN_CORR = "$ANNDIR/MANIFEST.$ANNCOL.correspondence.yml";
my $ANN_MAN_DESCR = "$ANNDIR/MANIFEST.$ANNCOL.descriptions.yml";
my $ANN_README = "$ANNDIR/README.$ANNCOL.yml";
my $GNM_MAN_CORR = "$GNMDIR/MANIFEST.$GNMCOL.correspondence.yml";
my $GNM_MAN_DESCR = "$GNMDIR/MANIFEST.$GNMCOL.descriptions.yml";
my $GNM_README = "$GNMDIR/README.$GNMCOL.yml";

my $to_name_base;
my ($GENE_HASH, $CHR_HASH);
my ($printed_man_corr_head, $printed_man_descr_head);

##################################################
# Call subroutines
&setup;
&make_chr_hash;
&make_gene_hash; 
if ( $all || $readme ){ &readme }
if ( $all || $ann_as_is ){ &ann_as_is }
if ( $all || $gnm_as_is ){ &gnm_as_is }
if ( $all || $cds ){ &cds }
if ( $all || $protein ){ &protein }
if ( $all || $gff ){ &gff }
if ( $all || $assembly ){ &assembly }

##################################################
sub setup {
  say "\n== Setup: Create output directories and start the metadata files ==";

  # Make collection directories
  say "Output directories:\n  $WD/annotations\n  $WD/genomes";
  unless (-d "$WD/annotations") {mkdir "$WD/annotations" or die "Can't make directory $WD/annotations: $!\n"}
  unless (-d $ANNDIR) {mkdir $ANNDIR or die "Can't make directory $ANNDIR: $!\n"}
  unless (-d "$WD/genomes") {mkdir "$WD/genomes" or die "Can't make directory $WD/genomes: $!\n"}
  unless (-d $GNMDIR) {mkdir $GNMDIR or die "Can't make directory $GNMDIR: $!\n"}

  # Remove existing metadata files UNLESS -extend is set.
  for my $file ($ANN_MAN_CORR, $ANN_MAN_DESCR, $ANN_README, 
                $GNM_MAN_CORR, $GNM_MAN_DESCR, $GNM_README){
    if (-e $file && not $extend){ unlink $file or die "Can't unlink metadata file $file: $!" }
  }
}

##################################################
sub make_chr_hash {
  say "\n== Making a hash of old/new chromosome and scaffold IDs, to go to the genomes directory ==";
  # Get path to main genome assembly input file, and regex for chromosomes and scaffolds
  my $GENOME_FILE_START;
  for my $fr_to_hsh (@{$confobj->{from_to_genome}}){ 
    if ($fr_to_hsh->{to} =~ /genome_main/){
      $GENOME_FILE_START = 
        "$WD/$dir_hsh{from_genome_dir}/$prefix_hsh{from_genome_prefix}.$fr_to_hsh->{from}";
    }
  }
  say $GENOME_FILE_START;
  unless (-e $GENOME_FILE_START) {
    die "File $GENOME_FILE_START doesn't exist. Check filename components in config file.\n"
  }
  
  if ($chr_hash){ 
    say "Hash of old/new chromosome & scaffold IDs has been provided:\n  $chr_hash";
    $CHR_HASH = $chr_hash;
  }
  else { 
    $CHR_HASH = "$WD/genomes/$GNMCOL/$GENSP.$GNMCOL.chr_name_hash.tsv";
    open (my $CHR_HASH_FH, ">", $CHR_HASH) or die "Can't open out $CHR_HASH: $!\n";
    say "Generating hash of old/new chromosome & scaffold IDs.";
    open(my $GNM_MAIN_FH, "gzcat $GENOME_FILE_START|") or die "Can't do gzcat $GENOME_FILE_START|: $!";
    while (my $line = <$GNM_MAIN_FH>){
      if ($line =~ /^>(\S+)/){
        my $chr = $1;
        say "$chr\t$TO_GNM_PREFIX.$chr";
        say $CHR_HASH_FH "$chr\t$TO_GNM_PREFIX.$chr";
      }
    }
  }
  my $TO_FILE = $CHR_HASH;
  my $FROM_FILE = "No prior file";
  my $description = "Hash file of old/new chromosome and scaffold IDs";
  ($printed_man_corr_head, $printed_man_descr_head) = (0, 0);
  &write_manifests($TO_FILE, $FROM_FILE, $GNM_MAN_CORR, $GNM_MAN_DESCR, $description);
}

##################################################
sub make_gene_hash {
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
      say "  Splice regex: $SPLICE_RX";
    }
  }
  say $CDS_FILE_START;
  unless (-e $CDS_FILE_START) {
    die "File $CDS_FILE_START doesn't exist. Check filename components in config file.\n"
  }
  
  if ($gene_hash){ 
    say "Hash of old/new gene IDs has been provided:\n  $gene_hash";
    $GENE_HASH = $gene_hash;
  }
  else {
    say "Generating hash of old/new gene IDs.";
    open(my $CDS_IN_FH, "gzcat $CDS_FILE_START |") or die "Can't do gzcat $CDS_FILE_START|: $!";
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
  my $TO_FILE = $GENE_HASH;
  my $FROM_FILE = "No prior file";
  my $description = "Hash file of old/new gene IDs";
  ($printed_man_corr_head, $printed_man_descr_head) = (0, 0);
  &write_manifests($TO_FILE, $FROM_FILE, $ANN_MAN_CORR, $ANN_MAN_DESCR, $description);
}

##################################################
sub readme {
  say "\n== Writing README files ==";
  my @readme_keys = qw(identifier provenance source synopsis scientific_name taxid scientific_name_abbrev 
         genotype description bioproject sraproject dataset_doi genbank_accession original_file_creation_date 
         local_file_creation_date dataset_release_date publication_doi publication_title 
         contributors citation data_curators public_access_level license keywords);
  
  $readme_hsh{scientific_name} = $scientific_name;
  $readme_hsh{genotype} = "\n  - $coll_hsh{genotype}";
  $readme_hsh{scientific_name_abbrev} = $GENSP;
  
  # Assembly README
  open(my $GNM_README_FH, '>>', $GNM_README) or die "Can't open out $GNM_README: $!";
  print $GNM_README_FH "---\n";
  $readme_hsh{identifier} = $GNMCOL;
  $readme_hsh{synopsis} = $readme_hsh{synopsis_genome};
  $readme_hsh{description} = $readme_hsh{description_genome};
  if ($readme_hsh{dataset_doi_genome}){$readme_hsh{dataset_doi} = "\"$readme_hsh{dataset_doi_genome}\""}
  else {$readme_hsh{dataset_doi} = ""}
  for my $key (@readme_keys){
    if ($key =~ /provenance|source|description|synopsis|title|citation|date/){ # wrap in quotes
      say $GNM_README_FH "$key: \"$readme_hsh{$key}\"\n"
    }
    else { # presume no quotes needed
      say $GNM_README_FH "$key: $readme_hsh{$key}\n"
    }
  }

  # Annotation README
  open(my $ANN_README_FH, '>>', $ANN_README) or die "Can't open out $ANN_README: $!";
  print $ANN_README_FH "---\n";
  $readme_hsh{identifier} = $ANNCOL;
  $readme_hsh{synopsis} = $readme_hsh{synopsis_annot};
  $readme_hsh{description} = $readme_hsh{description_annot};
  if ($readme_hsh{dataset_doi_annot}){$readme_hsh{dataset_doi} = "\"$readme_hsh{dataset_doi_annot}\""}
  else {$readme_hsh{dataset_doi} = ""}
  for my $key (@readme_keys){
    if ($key =~ /provenance|source|description|synopsis|title|citation|date/){ # wrap in quotes
      say $ANN_README_FH "$key: \"$readme_hsh{$key}\"\n"
    }
    else { # presume no quotes needed
      say $ANN_README_FH "$key: $readme_hsh{$key}\n"
    }
  }
}

##################################################
sub ann_as_is {
  say "\n== Copying over \"as-is\" annotation information files, if present, unchanged ==";
  for my $fr_to_hsh (@{$confobj->{from_to_annot_as_is}}){ 
    my $FROM_FILE = "$WD/$dir_hsh{from_annot_dir}/$prefix_hsh{from_annot_prefix}.$fr_to_hsh->{from}";
    my $TO_FILE = "$ANNDIR/$GENSP.$ANNCOL.$fr_to_hsh->{to}";
    say "Converting from ... to ...:\n  $FROM_FILE\n  $TO_FILE";
    &write_manifests($TO_FILE, $FROM_FILE, $ANN_MAN_CORR, $ANN_MAN_DESCR, $fr_to_hsh->{description});
    if ($FROM_FILE =~ /gz$/){ 
      open(my $AS_IS_FROM_FH, "gzcat $FROM_FILE |") or die "Can't do gunzip $FROM_FILE|: $!";
      open(my $AS_IS_TO_FH, ">", $TO_FILE) or die "Can't open out $TO_FILE: $!\n";
      while (<$AS_IS_FROM_FH>) {
        print $AS_IS_TO_FH $_;
      }
    } 
    else { # else file isn't gzipped, so just copy it
      copy($FROM_FILE, $TO_FILE) or die "Can't copy files: $!";
    }
  }
}

##################################################
sub gnm_as_is {
  say "\n== Copying over \"as-is\" genome information files, if present, unchanged ==";
  for my $fr_to_hsh (@{$confobj->{from_to_genome_as_is}}){ 
    my $FROM_FILE = "$WD/$dir_hsh{from_genome_dir}/$prefix_hsh{from_genome_prefix}.$fr_to_hsh->{from}";
    my $TO_FILE = "$GNMDIR/$GENSP.$GNMCOL.$fr_to_hsh->{to}";
    say "Converting from ... to ...:\n  $FROM_FILE\n  $TO_FILE";
    &write_manifests($TO_FILE, $FROM_FILE, $GNM_MAN_CORR, $GNM_MAN_DESCR, $fr_to_hsh->{description});
    if ($FROM_FILE =~ /gz$/){
      open(my $AS_IS_FROM_FH, "gzcat $FROM_FILE |") or die "Can't do gunzip $FROM_FILE|: $!";
      open(my $AS_IS_TO_FH, ">", $TO_FILE) or die "Can't open out $TO_FILE: $!\n";
      while (<$AS_IS_FROM_FH>) {
        print $AS_IS_TO_FH $_;
      }
    } 
    else { # else file isn't gzipped, so just copy it
      copy($FROM_FILE, $TO_FILE) or die "Can't copy files: $!";
    }
  }
}

##################################################
sub cds {
  say "\n== Processing the gene nucleotide files (CDS, mRNA) ==";
  for my $fr_to_hsh (@{$confobj->{from_to_cds_mrna}}){ 
    my $FROM_FILE = "$WD/$dir_hsh{from_annot_dir}/$prefix_hsh{from_annot_prefix}.$fr_to_hsh->{from}"; 
    my $TO_FILE = "$ANNDIR/$GENSP.$ANNCOL.$fr_to_hsh->{to}";
    say "Converting from ... to ...:\n  $FROM_FILE\n  $TO_FILE";
    my $SPLICE_RX = $fr_to_hsh->{splice};
    $SPLICE_RX =~ s/["']//g; # Strip surrounding quotes if any. We'll add them below.
    say "  SPLICE REGEX: \"$SPLICE_RX\"";
    my $ARGS = "-hash $GENE_HASH -fasta $FROM_FILE -splice \"$SPLICE_RX\" -nodef -out $TO_FILE";
    system("hash_into_fasta_id.pl $ARGS");
    &write_manifests($TO_FILE, $FROM_FILE, $ANN_MAN_CORR, $ANN_MAN_DESCR, $fr_to_hsh->{description});
  }
}

##################################################
sub protein {
  say "\n== Processing the protein sequence files ==";
  for my $fr_to_hsh (@{$confobj->{from_to_protein}}){ 
    my $FROM_FILE = "$WD/$dir_hsh{from_annot_dir}/$prefix_hsh{from_annot_prefix}.$fr_to_hsh->{from}"; 
    my $TO_FILE = "$ANNDIR/$GENSP.$ANNCOL.$fr_to_hsh->{to}";
    say "Converting from ... to ...:\n  $FROM_FILE\n  $TO_FILE";
    &write_manifests($TO_FILE, $FROM_FILE, $ANN_MAN_CORR, $ANN_MAN_DESCR, $fr_to_hsh->{description});
    my $SPLICE_RX = $fr_to_hsh->{splice};
    $SPLICE_RX =~ s/["']//g; # Strip surrounding quotes if any. We'll add them below.
    my $STRIP_RX = $fr_to_hsh->{strip};
    $STRIP_RX =~ s/["']//g; # Strip surrounding quotes if any. We'll add them below.
    say "  SPLICE REGEX: \"$SPLICE_RX\"";
    say "  STRIP REGEX: \"$STRIP_RX\"";
    my $ARGS = "-hash $GENE_HASH -fasta $FROM_FILE -splice \"$SPLICE_RX\" -strip \"$STRIP_RX\" -nodef -out $TO_FILE";
    system("hash_into_fasta_id.pl $ARGS");
  }
}

##################################################
sub gff {
  say "\n== Processing the GFF files ==";
  for my $fr_to_hsh (@{$confobj->{from_to_gff}}){ 
    my $FROM_FILE = "$WD/$dir_hsh{from_annot_dir}/$prefix_hsh{from_annot_prefix}.$fr_to_hsh->{from}"; 
    my $TO_FILE = "$ANNDIR/$GENSP.$ANNCOL.$fr_to_hsh->{to}";
    say "Converting from ... to ...:\n  $FROM_FILE\n  $TO_FILE";
    &write_manifests($TO_FILE, $FROM_FILE, $ANN_MAN_CORR, $ANN_MAN_DESCR, $fr_to_hsh->{description});
    my $STRIP_RX = $fr_to_hsh->{strip};
    $STRIP_RX =~ s/["']//g; # Strip surrounding quotes if any. We'll add them below.
    say "  STRIP REGEX: \"$STRIP_RX\"";
    my $ARGS = "-gff $FROM_FILE -gene_hash $GENE_HASH -seqid_hash $CHR_HASH -strip \"$STRIP_RX\" -sort -out $TO_FILE";
    system("hash_into_gff_id.pl $ARGS");
    if ($fr_to_hsh->{to} =~ /gene_models_main.gff3/) {
      say "  Generating CDS bed file from GFF";
      my $bed_file = $TO_FILE;
      $bed_file =~ s/gene_models_main.gff3/cds.bed/;
      my $gff_to_bed_command = "cat $TO_FILE | gff_to_bed6_mRNA.awk | sort -k1,1 -k2n,2n > $bed_file";
      #system($gff_to_bed_command) or die "system call failed: $?";
      `$gff_to_bed_command`;
      &write_manifests($bed_file, $FROM_FILE, $ANN_MAN_CORR, $ANN_MAN_DESCR, "BED-format file, derived from gene_models_main.gff3");
    }
  }
}

##################################################
sub assembly {
  say "\n== Processing the genome assembly files ==";
  for my $fr_to_hsh (@{$confobj->{from_to_genome}}){ 
    my $FROM_FILE = "$WD/$dir_hsh{from_genome_dir}/$prefix_hsh{from_genome_prefix}.$fr_to_hsh->{from}";
    my $TO_FILE = "$GNMDIR/$GENSP.$GNMCOL.$fr_to_hsh->{to}";
    say "Converting from ... to ...:\n  $FROM_FILE\n  $TO_FILE";
    &write_manifests($TO_FILE, $FROM_FILE, $GNM_MAN_CORR, $GNM_MAN_DESCR, $fr_to_hsh->{description});
    my $ARGS = "-hash $CHR_HASH -fasta $FROM_FILE -nodef -out $TO_FILE";
    system("hash_into_fasta_id.pl $ARGS");
  }
}

##################################################
sub write_manifests {
  my ($TO_FILE, $FROM_FILE, $CORR, $DESCR, $description) = @_;
  my $to_name_base = basename($TO_FILE);
  my $from_name_base = basename($FROM_FILE);

  open (my $CORR_OFH, ">>", $CORR) or die "Can't open out $CORR: $!";
  open (my $CORR_IFH, "<", $CORR) or die "Can't open in $CORR: $!";
  open (my $DESCR_OFH, ">>", $DESCR) or die "Can't open out $DESCR: $!";
  open (my $DESCR_IFH, "<", $DESCR) or die "Can't open in $DESCR: $!";

  # Don't print redundant lines (which might happen in multiple runs, if "-extend" is set
  my (%seen_to_file);
  while (<$CORR_IFH>){
    chomp;
    my $filename = $_;
    $filename =~ s/^(\S+).gz: .+/$1/;
    $filename =~ s/^(\S+): .+/$1/;
    #say "  seen CORR:  $filename";
    $seen_to_file{$filename}++ if ($filename =~ $to_name_base);
    if ($. == 1 && $_ =~ /^---/){ $printed_man_corr_head++ }
  }
  while (<$DESCR_IFH>){ 
    chomp;
    my $filename = $_;
    $filename =~ s/^(\S+).gz: .+/$1/;
    $filename =~ s/^(\S+): .+/$1/;
    #say "  seen DESCR: $filename";
    $seen_to_file{$filename}++ if ($filename =~ $to_name_base);
    if ($. == 1 && $_ =~ /^---/){ $printed_man_descr_head++ }
  }

  unless ($printed_man_corr_head){
    say $CORR_OFH "---\n# filename in this repository: previous names";
    $printed_man_corr_head++;
  }
  unless ($printed_man_descr_head){
    say $DESCR_OFH "---\n# filename in this repository: description";
    $printed_man_descr_head++;
  }
  
  unless ($seen_to_file{$to_name_base}){
    my $separator;
    if ( $to_name_base =~ /readme.txt|html/ ){ $separator = ":" }
    else { $separator = ".gz:" }
    print $CORR_OFH "$to_name_base$separator $from_name_base\n";
    print $DESCR_OFH "$to_name_base$separator $description\n";
  }
}

