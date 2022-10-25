#!/usr/bin/env perl

use warnings;
use strict;
use YAML::Tiny 'LoadFile';
use Getopt::Long;
use File::Copy;
use File::Basename;
use feature "say";

my $usage = <<EOS;
  Synopsis: ds_souschef_id_map.pl -config CONFIG.yml

  This script uses information in a yaml-format config file to prepare data store 
  collections for genomic data, comprising genome assemblies and/or gene annotations. 
  The script also writes the associated metadata for the collections, including 
  the README and MANIFEST files. Check that all fields have been populated in the README.

  By default, all files will be converted (assemblies and annotation files).
  Particular types can be run separately (e.g. just the protein files or just assemblies),
  but then either provide the path to the chromosome map file (-seqid_map) for -gff and -assembly,
  and the gene map file (-featid_map) for -cds, -protein, and -gff.

  Note that all input files are assumed to be in two directories, e.g. annotation and assembly.
  If there are release-policy or readme files that pertain to the assembly+annotation as a whole, 
  then FIRST COPY THESE INTO the annotation and assembly directories. The program won't find them 
  outside the specified directories. Provide full filenames for these files in the config file. 

  Required:
    -config    (string) yaml-format file with information for the metadata and the file conversions.
  Options:
    -seqid_map (string) Path to file with mapping (hash) of old/new chromosome & scaffold IDs.
                  Will be calculated unless specified here.
    -featid_map (string) Path to file with mapping (hash) of old/new gene IDs.
                  Will be calculated unless specified here.
    -all       (boolean) True by default, unless one or more of the modules below are specified.
  Set one or more of the following flags to run just those modules. If none are specified, "all" is implied.
    -make_featid_map (boolean) Generate hash file/mapping of feature IDs (genes & gene components).
    -make_seqid_map  (boolean) Generate hash file/mapping of chromosome and scaffold IDs.
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

my ($config, $seqid_map, $featid_map, $help); 
my ($readme, $ann_as_is, $gnm_as_is, $cds, $protein, $gff, $assembly, $all, $extend);
my ($make_featid_map, $make_seqid_map);

GetOptions (
  "config=s" =>    \$config,  # required
  "seqid_map:s" => \$seqid_map,
  "featid_map:s" => \$featid_map,
  "make_featid_map" =>  \$make_featid_map,
  "make_seqid_map" =>   \$make_seqid_map,
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

if ($seqid_map){
  unless ( -e $seqid_map ){ die "Chromosome hash file not found at $seqid_map.\n" .
     "Please provide full path, or omit this flag to have the hash calculated.\n" }
}

if ($featid_map){
  unless ( -e $featid_map ){ die "Gene hash file not found at $seqid_map.\n" . 
    "Please provide full path, or omit this flag to have the hash calculated.\n" }
}

# All modules will be run unless flags are set for one or more of the particular modules.
$all++ unless ($make_featid_map || $make_seqid_map || $readme || $ann_as_is || $gnm_as_is || $cds || $protein || $gff || $assembly);

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
my ($FEATID_MAP, $SEQID_MAP);
my ($printed_man_corr_head, $printed_man_descr_head);

##################################################
# Call subroutines
&setup;
if ( $all || $make_seqid_map ){ &make_seqid_map }
if ($seqid_map && !($make_seqid_map)){ 
  say "Map of old/new chromosome & scaffold IDs has been provided:\n  $seqid_map";
  $SEQID_MAP = $seqid_map;
}

if ( $all || $make_featid_map ){ &make_featid_map }
if ($featid_map && !($make_featid_map)){ 
  say "Hash of old/new gene IDs has been provided:\n  $featid_map";
  $FEATID_MAP = $featid_map;
}

if ( $all || $readme ){ &readme }
if ( $all || $ann_as_is ){ &ann_as_is }
if ( $all || $gnm_as_is ){ &gnm_as_is }

if ( $gff && (!$FEATID_MAP || !$SEQID_MAP) ){
  die "\nERROR: If the -gff flag is set, then also call -make_seqid_map and -make_featid_map OR provde the map files via -featid_map and -seqid_map\n\n";
}

if ( $assembly && !$SEQID_MAP ){
  die "\nERROR: If the -assembly flag is set, then also call the -make_seqid_map OR provide the chromosome map file via -seqid_map\n\n";
}

if ( $cds || $protein && !$FEATID_MAP ){
  die "\nERROR: If the -cds or -protein flags are set, then also call -make_featid_map OR provide the feature-id map file via -featid_map\n\n";
}

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
sub make_seqid_map {
  say "\n== Making a map (hash) of old/new chromosome and scaffold IDs, to go to the genomes directory ==";
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
  
  $SEQID_MAP = "$WD/genomes/$GNMCOL/$GENSP.$GNMCOL.seqid_map.tsv";
  open (my $SEQID_MAP_FH, ">", $SEQID_MAP) or die "Can't open out $SEQID_MAP: $!\n";
  say "Generating map of old/new chromosome & scaffold IDs.";
  open(my $GNM_MAIN_FH, "gzcat $GENOME_FILE_START|") or die "Can't do gzcat $GENOME_FILE_START|: $!";
  while (my $line = <$GNM_MAIN_FH>){
    if ($line =~ /^>(\S+)/){
      my $chr = $1;
      say "$chr\t$TO_GNM_PREFIX.$chr";
      say $SEQID_MAP_FH "$chr\t$TO_GNM_PREFIX.$chr";
    }
  }

  my $TO_FILE = $SEQID_MAP;
  my $FROM_FILE = "No prior file";
  my $description = "Map (hash) file of old/new chromosome and scaffold IDs";
  ($printed_man_corr_head, $printed_man_descr_head) = (0, 0);
  &write_manifests($TO_FILE, $FROM_FILE, $GNM_MAN_CORR, $GNM_MAN_DESCR, $description);
}

##################################################
sub make_featid_map {
  say "\n== Making a map (hash) of old/new gene IDs, to go to the annotations directory ==";
  # Get path to main GFF input file
  my $GFF_FILE_START;
  my ($strip_regex, $STRIP_RX);
  for my $fr_to_hsh (@{$confobj->{from_to_gff}}){ # Get the "strip" regex, if any, from the conf file
    if ($fr_to_hsh->{to} =~ /gene_models_main.gff3/){
      $GFF_FILE_START = 
        "$dir_hsh{work_dir}/$dir_hsh{from_annot_dir}/$prefix_hsh{from_annot_prefix}.$fr_to_hsh->{from}";
      $strip_regex = $fr_to_hsh->{strip};
      $strip_regex =~ s/["']//g; # Strip surrounding quotes if any. We'll add them below.
      if ( $strip_regex ){ $STRIP_RX=qr/$strip_regex/ }
      else { $STRIP_RX=qr/$/ }
      say "  STRIP REGEX: \"$STRIP_RX\"";
    }
  }
  say $GFF_FILE_START;
  unless (-e $GFF_FILE_START) {
    die "File $GFF_FILE_START doesn't exist. Check filename components in config file.\n"
  }
  
  say "Generating hash of old/new gene IDs.";
  open(my $GFF_IN_FH, "gzcat $GFF_FILE_START |") or die "Can't do gzcat $GFF_FILE_START|: $!";
  $FEATID_MAP = "$WD/annotations/$ANNCOL/$GENSP.$ANNCOL.featid_map.tsv";
  open (my $FEATID_MAP_FH, ">", $FEATID_MAP) or die "Can't open out $FEATID_MAP: $!\n";
  my %seen_gene_id;
  while (my $line = <$GFF_IN_FH>){
    chomp $line;
    next if ($line =~ /^#|^\s*$/);
    my @parts = split(/\t/, $line);
    my $gene_id = $parts[8];
    $gene_id =~ s/ID=([^;]+);.+/$1/;
    if (defined $strip_regex){
      $gene_id =~ s/$STRIP_RX//g;
    }
    unless ( $seen_gene_id{$gene_id} ) {
      $seen_gene_id{$gene_id}++;
      say $FEATID_MAP_FH "$gene_id\t$TO_ANN_PREFIX.$gene_id";
    }
  }

  my $TO_FILE = $FEATID_MAP;
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
  if (scalar(@{$confobj->{original_readme_and_usage}})>0){
    say "\n== Copying the original README and/or usage agreement files into the annotations directory ==";
  }
  for my $fr_to_hsh (@{$confobj->{original_readme_and_usage}}){ 
    my $FROM_FILE = "$WD/$dir_hsh{from_annot_dir}/$fr_to_hsh->{from_full_filename}";
    my $TO_FILE = "$ANNDIR/$GENSP.$ANNCOL.$fr_to_hsh->{to}";
    say "Converting from ... to ...:\n  $FROM_FILE\n  $TO_FILE";
    &write_manifests($TO_FILE, $FROM_FILE, $ANN_MAN_CORR, $ANN_MAN_DESCR, $fr_to_hsh->{description});
    copy($FROM_FILE, $TO_FILE) or die "Can't copy files: $!"; # Should be uncompressed text files
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
  if (scalar(@{$confobj->{original_readme_and_usage}})>0){
    say "\n== Copying the original README and/or usage agreement files into the genomes directory ==";
  }
  for my $fr_to_hsh (@{$confobj->{original_readme_and_usage}}){ 
    my $FROM_FILE = "$WD/$dir_hsh{from_genome_dir}/$fr_to_hsh->{from_full_filename}";
    my $TO_FILE = "$GNMDIR/$GENSP.$GNMCOL.$fr_to_hsh->{to}";
    say "Converting from ... to ...:\n  $FROM_FILE\n  $TO_FILE";
    &write_manifests($TO_FILE, $FROM_FILE, $GNM_MAN_CORR, $GNM_MAN_DESCR, $fr_to_hsh->{description});
    copy($FROM_FILE, $TO_FILE) or die "Can't copy files: $!"; # Should be uncompressed text files
  }
}

##################################################
sub cds {
  say "\n== Processing the gene nucleotide files (CDS, mRNA) ==";
  for my $fr_to_hsh (@{$confobj->{from_to_cds_mrna}}){ 
    my $FROM_FILE = "$WD/$dir_hsh{from_annot_dir}/$prefix_hsh{from_annot_prefix}.$fr_to_hsh->{from}"; 
    my $TO_FILE = "$ANNDIR/$GENSP.$ANNCOL.$fr_to_hsh->{to}";
    say "Converting from ... to ...:\n  $FROM_FILE\n  $TO_FILE";
    &write_manifests($TO_FILE, $FROM_FILE, $ANN_MAN_CORR, $ANN_MAN_DESCR, $fr_to_hsh->{description});
    my $ARGS;
    my $STRIP_RX = $fr_to_hsh->{strip};
    if (defined $STRIP_RX){
      $STRIP_RX =~ s/["']//g; # Strip surrounding quotes if any. We'll add them below.
      say "  STRIP REGEX: \"$STRIP_RX\"";
      $ARGS = "-hash $FEATID_MAP -fasta $FROM_FILE -strip \"$STRIP_RX\" -nodef -out $TO_FILE";
    }
    else {
      $ARGS = "-hash $FEATID_MAP -fasta $FROM_FILE -nodef -out $TO_FILE";
    }
    system("hash_into_fasta_id.pl $ARGS");
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
    my $ARGS;
    my $STRIP_RX = $fr_to_hsh->{strip};
    if (defined $STRIP_RX){
      $STRIP_RX =~ s/["']//g; # Strip surrounding quotes if any. We'll add them below.
      say "  STRIP REGEX: \"$STRIP_RX\"";
      $ARGS = "-hash $FEATID_MAP -fasta $FROM_FILE -strip \"$STRIP_RX\" -nodef -out $TO_FILE";
    }
    else {
      $ARGS = "-hash $FEATID_MAP -fasta $FROM_FILE -nodef -out $TO_FILE";
    }
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
    my $ARGS;
    my $STRIP_RX = $fr_to_hsh->{strip};
    if (defined $STRIP_RX){
      $STRIP_RX =~ s/["']//g; # Strip surrounding quotes if any. We'll add them below.
      say "  STRIP REGEX: \"$STRIP_RX\"";
      $ARGS = "-gff $FROM_FILE -featid_map $FEATID_MAP -seqid_map $SEQID_MAP -strip \"$STRIP_RX\" -sort -out $TO_FILE";
    }
    else {
      $ARGS = "-gff $FROM_FILE -featid_map $FEATID_MAP -seqid_map $SEQID_MAP -sort -out $TO_FILE";
    }
    system("hash_into_gff_id.pl $ARGS");
    if ($fr_to_hsh->{to} =~ /gene_models_main.gff3/) {
      say "  Generating CDS bed file from GFF";
      my $bed_file = $TO_FILE;
      $bed_file =~ s/gene_models_main.gff3/cds.bed/;
      my $gff_to_bed_command = "cat $TO_FILE | gff_to_bed6_mRNA.awk | sort -k1,1 -k2n,2n > $bed_file";
      `$gff_to_bed_command`; # or die "system call of gff_to_bed6_mRNA.awk failed: $?";
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
    my $ARGS = "-hash $SEQID_MAP -fasta $FROM_FILE -nodef -out $TO_FILE";
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

__END__

Steven Cannon
Versions
2022-10-24 New named script, "ds_souschef_id_map.pl", deriving from 2022-10-17 ds_souschef_genomic.pl
           The main difference is that ..._id_map.pl uses full hash/map of all features, whereas 
           ..._genomic.pl uses just mapping files with the base gene IDs, excluding splice forms and subfeatures.
           Also, handling of original readme and usage files is more flexible (entailing a change in the config).

