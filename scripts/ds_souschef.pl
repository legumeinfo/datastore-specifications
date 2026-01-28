#!/usr/bin/env perl

use warnings;
use strict;
use YAML::Tiny 'LoadFile';
use Getopt::Long;
use File::Copy;
use File::Basename;
use feature "say";

my $usage = <<EOS;
  Synopsis: ds_souschef.pl -config CONFIG.yml
    OR, to just calculate GFFs, given pre-calculated sequid and featid maps (passed in as variables):
      ds_souschef.pl -config CONFIG.yml -seqid_map \$SM -featid_map \$FM -gff 
    OR, to just calculate the README file:
      ds_souschef.pl -config CONFIG.yml -readme

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
    -SHash     (string) Path to file with initial mapping of old/new chromosome & scaffold IDs, e.g. 
                   CM012345.1  Chr01
                 This is distinct from the Data Store prefixing in creation of the seqid_map.
    -seqid_map (string) Path to file with mapping (hash) of old/new chromosome & scaffold IDs.
                  This adds the Data Store prefix. Will be calculated unless specified here.
    -featid_map (string) Path to file with mapping (hash) of old/new gene IDs.
                  Will be calculated unless specified here.
                  Note that the hashed (new) gene ID can be reshaped somewhat with the use of 
                  a "strip" pattern in the from_to_gff section of the config. For example, 
                    strip: 'gnl\|WGS:JAKRYI\|' 
                  ... will strip those characters from GenBank feature IDs.
    -all       (boolean) True by default, unless one or more of the modules below are specified.
  Set one or more of the following flags to run just those modules. If none are specified, "all" is implied.
    -make_featid_map (boolean) Generate hash file/mapping of feature IDs (genes & gene components).
    -make_seqid_map  (boolean) Generate hash file/mapping of chromosome and scaffold IDs.
    -readme    (boolean) Generate the README files. 
    -ann_as_is (boolean) Copy over the "as-is" annotation files (un-transformed).
    -gff_as_is (boolean) Copy over the "as-is" gff files (un-transformed).
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
my ($readme, $ann_as_is, $gff_as_is, $gnm_as_is, $cds, $protein, $gff, $assembly, $all, $extend);
my ($make_featid_map, $make_seqid_map, $SHash);

GetOptions (
  "config=s" =>    \$config,  # required
  "SHash:s" =>     \$SHash,
  "seqid_map:s" => \$seqid_map,
  "featid_map:s" => \$featid_map,
  "make_featid_map" =>  \$make_featid_map,
  "make_seqid_map" =>   \$make_seqid_map,
  "readme" =>      \$readme,
  "ann_as_is" =>   \$ann_as_is,
  "gff_as_is" =>   \$gff_as_is,
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

if ($SHash){
  unless ( -e $SHash){ die "Chromosome hash file not found at $SHash.\n" }
}

if ($featid_map){
  unless ( -e $featid_map ){ die "Gene hash file not found at $seqid_map.\n" . 
    "Please provide full path, or omit this flag to have the hash calculated.\n" }
}

# All modules will be run unless flags are set for one or more of the particular modules.
$all++ unless ($make_featid_map || $make_seqid_map || $readme || 
               $ann_as_is || $gff_as_is || $gnm_as_is || $cds || $protein || $gff || $assembly);

my $yaml = YAML::Tiny->read( $config );

my $confobj = LoadFile($config);

my %coll_hsh;
my $COLLECTION_TYPE;
for (keys %{$confobj->{collection_info}}){ 
  $coll_hsh{$_} = $confobj->{collection_info}->{$_};
  if ( $_ =~ /annot|genome/ ){ $COLLECTION_TYPE="genomic" }
  elsif ( $_ =~ /pan/ ){ $COLLECTION_TYPE="pangene" }
}
say "COLLECTION_TYPE: $COLLECTION_TYPE";

my %dir_hsh;
for (keys %{$confobj->{directories}}){ $dir_hsh{$_} = $confobj->{directories}->{$_} }

my %prefix_hsh;
for (keys %{$confobj->{prefixes}}){ 
  $prefix_hsh{$_} = $confobj->{prefixes}->{$_};
}

my %readme_hsh;
for (keys %{$confobj->{readme_info}}){ $readme_hsh{$_} = $confobj->{readme_info}->{$_} }

# Make some variables for prefixes, for convenience
my $WD = "$dir_hsh{work_dir}";
my $GENSP = $coll_hsh{scientific_name_abbrev};

my ($GNMCOL, $ANN_GT_VER, $ANNCOL, $scientific_name, $TO_GNM_PREFIX, $TO_ANN_PREFIX, $ANNDIR, $GNMDIR);
my ($GNM_MAN, $GNM_README, $GNM_CHANGES);
my ($ANN_MAN, $ANN_README, $ANN_CHANGES);
my ($PANCOL, $TO_PAN_PREFIX, $PANDIR, $PAN_MAN, $PAN_README, $PAN_CHANGES);

if ($COLLECTION_TYPE =~ /genomic/){
  $GNMCOL = "$coll_hsh{coll_genotype}.$coll_hsh{gnm_ver}.$coll_hsh{genome_key}";
  $ANN_GT_VER = "$coll_hsh{coll_genotype}.$coll_hsh{gnm_ver}.$coll_hsh{ann_ver}";
  $ANNCOL = "$coll_hsh{coll_genotype}.$coll_hsh{gnm_ver}.$coll_hsh{ann_ver}.$coll_hsh{annot_key}";
  $scientific_name = "$coll_hsh{genus} $coll_hsh{species}";
  $TO_GNM_PREFIX = "$GENSP.$coll_hsh{coll_genotype}.$coll_hsh{gnm_ver}";
  $TO_ANN_PREFIX = "$GENSP.$coll_hsh{coll_genotype}.$coll_hsh{gnm_ver}.$coll_hsh{ann_ver}";
  
  $ANNDIR = "$WD/annotations/$ANNCOL";
  $GNMDIR = "$WD/genomes/$GNMCOL";
  
  $ANN_MAN = "$ANNDIR/MANIFEST.$ANNCOL.yml";
  $ANN_README = "$ANNDIR/README.$ANNCOL.yml";
  $ANN_CHANGES = "$ANNDIR/CHANGES.$ANNCOL.txt";
  
  $GNM_MAN = "$GNMDIR/MANIFEST.$GNMCOL.yml";
  $GNM_README = "$GNMDIR/README.$GNMCOL.yml";
  $GNM_CHANGES = "$GNMDIR/CHANGES.$GNMCOL.txt";
}
elsif ($COLLECTION_TYPE =~ /pangene/){
  $scientific_name = "$coll_hsh{genus}";
  $GENSP = "$coll_hsh{genus}";
  $PANCOL = "$scientific_name.$coll_hsh{pan_ver}.$coll_hsh{pan_key}";
  $TO_PAN_PREFIX = "$scientific_name.$coll_hsh{pan_ver}";
  
  $PANDIR = "$WD/pangenes/$PANCOL";
  
  $PAN_MAN = "$PANDIR/MANIFEST.$PANCOL.yml";
  $PAN_README = "$PANDIR/README.$PANCOL.yml";
  $PAN_CHANGES = "$PANDIR/CHANGES.$PANCOL.txt";
}
else {warn "COLLECTION_TYPE not recognized: [$COLLECTION_TYPE]\n"; }

my $to_name_base;
my ($FEATID_MAP, $SEQID_MAP);
my ($printed_man_head, $printed_man_descr_head);

##################################################
# Call subroutines
&setup;

if ( $COLLECTION_TYPE =~ /pangene/ ) {
  say "Handle pangene config and collection";
  &pangene_tsv;
  &pangene_fasta;
  &pangene_as_is;
  &pangene_readme;
}
else { # Not a pangene job, so presume genomic
  if ( $all || $make_seqid_map ){ &make_seqid_map }
  if ($seqid_map && !($make_seqid_map)){ 
    say "Map of old/new chromosome & scaffold IDs has been provided:\n  $seqid_map";
    $SEQID_MAP = $seqid_map;
  }
  
  if ( $all || $make_featid_map ){ 
    &make_featid_map 
  }
  if ($featid_map && !($make_featid_map)){ 
    say "Hash of old/new gene IDs has been provided:\n  $featid_map";
    $FEATID_MAP = $featid_map;
  }
  
  if ( $all || $readme ){ &readme }
  if ( $all || $ann_as_is ){ &ann_as_is }
  if ( $all || $gnm_as_is ){ &gnm_as_is }
  if ( $all || $gff_as_is ){ &gff_as_is }
  
  if ( $gff && (!$FEATID_MAP || !$SEQID_MAP) ){
    die "\nERROR: If the -gff flag is set, then also call -make_seqid_map and -make_featid_map OR " . 
        "provde the map files via -featid_map and -seqid_map\n\n";
  }
  
  if ( $assembly && !$SEQID_MAP ){
    die "\nERROR: If the -assembly flag is set, then also call the -make_seqid_map OR " . 
        "provide the chromosome map file via -seqid_map\n\n";
  }
  
  if ( $cds || $protein && !$FEATID_MAP ){
    die "\nERROR: If the -cds or -protein flags are set, then also call -make_featid_map OR " . "
        provide the feature-id map file via -featid_map\n\n";
  }
  
  if ( $all || $cds ){ &cds }
  if ( $all || $protein ){ &protein }
  if ( $all || $gff ){ &gff }
  if ( $all || $assembly ){ &assembly }
}

##################################################
sub setup {
  say "\n== Setup: Create output directories and start the metadata files ==";

  # Make collection directories
  if ($COLLECTION_TYPE =~ /genomic/){
    say "Output directories:\n  $WD/annotations\n  $WD/genomes";
    unless (-d "$WD/annotations") {mkdir "$WD/annotations" or die "Can't make directory $WD/annotations: $!\n"}
    unless (-d $ANNDIR) {mkdir $ANNDIR or die "Can't make directory $ANNDIR: $!\n"}
    unless (-d "$WD/genomes") {mkdir "$WD/genomes" or die "Can't make directory $WD/genomes: $!\n"}
    unless (-d $GNMDIR) {mkdir $GNMDIR or die "Can't make directory $GNMDIR: $!\n"}
    # Remove existing metadata files UNLESS -extend is set.
    for my $file ($ANN_MAN, $ANN_README, $ANN_CHANGES, 
                  $GNM_MAN, $GNM_README, $GNM_CHANGES){
      if (-e $file && not $extend){ unlink $file or die "Can't unlink metadata file $file: $!" }
    }
  }
  elsif ($COLLECTION_TYPE =~ /pangene/){
    say "Output directories:\n  $WD/pangenes";
    unless (-d "$WD/pangenes") {mkdir "$WD/pangenes" or die "Can't make directory $WD/pangenes: $!\n"}
    unless (-d $PANDIR) {mkdir $PANDIR or die "Can't make directory $PANDIR: $!\n"}
    # Remove existing metadata files UNLESS -extend is set.
    for my $file ($PAN_MAN, $PAN_README, $PAN_CHANGES){
      if (-e $file && not $extend){ unlink $file or die "Can't unlink metadata file $file: $!" }
    }
  }
}

##################################################
sub make_seqid_map {
  if ($seqid_map){ 
    say "seqid_map has been provided, so don't calculate it";
    return 
  } 
  say "\n== Making a map (hash) of old/new chromosome and scaffold IDs, to go to the genomes directory ==";
  # Get path to main genome assembly input file, and regex for chromosomes and scaffolds
  my $GENOME_FILE_START;

  for my $fr_to_hsh (@{$confobj->{from_to_genome}}){ 
    if ($fr_to_hsh->{to} =~ /genome_main/){
      $GENOME_FILE_START = 
        "$WD/$dir_hsh{from_genome_dir}/$prefix_hsh{from_genome_prefix}$fr_to_hsh->{from}";
    }
  }
  say "GENOME_FILE_START: $GENOME_FILE_START";
  unless (-e $GENOME_FILE_START) {
    die "File $GENOME_FILE_START doesn't exist. Check filename components in config file.\n"
  }

  my $SHASH_FH;
  my %seqid_initial_hash;
  if ($SHash) {
    open (my $SHASH_FH, "<", $SHash) or die "Can't open in file $SHash: $!\n";
    # read hash
    while (<$SHASH_FH>) {
      chomp;
      /(\S+)\s+(.+)/;
      next if (/^#/);
      my ($id, $hash_val) = ($1,$2);
      $seqid_initial_hash{$id} = $hash_val;   # say "SHash: $id, $hash_val";
    }
  }
  
  $SEQID_MAP = "$WD/genomes/$GNMCOL/$GENSP.$GNMCOL.seqid_map.tsv";
  open (my $SEQID_MAP_FH, ">", $SEQID_MAP) or die "Can't open out $SEQID_MAP: $!\n";
  say "Generating map of old/new chromosome & scaffold IDs.";
  open(my $GNM_MAIN_FH, "zcat $GENOME_FILE_START|") or die "Can't do zcat $GENOME_FILE_START|: $!";
  my %patched_new_id;
  while (my $line = <$GNM_MAIN_FH>){
    if ($line =~ /^>(\S+)/){
      my $chr = $1;
      if ($SHash){
        my $new_chr_id = $chr;
        for my $id (keys %seqid_initial_hash){
          if ($new_chr_id =~ m/$id/){
            $new_chr_id = $seqid_initial_hash{$id};
            #say "$chr\t$TO_GNM_PREFIX.$new_chr_id";
            say $SEQID_MAP_FH "$chr\t$TO_GNM_PREFIX.$new_chr_id";
            $patched_new_id{$chr}++;
            last;
          }
        }
        unless ($patched_new_id{$chr}){
          #say "$chr\t$TO_GNM_PREFIX.$chr";
          say $SEQID_MAP_FH "$chr\t$TO_GNM_PREFIX.$chr";
        }
      }
      else {
        say "$chr\t$TO_GNM_PREFIX.$chr";
        say $SEQID_MAP_FH "$chr\t$TO_GNM_PREFIX.$chr";
      }
    }
  }

  my $TO_FILE = $SEQID_MAP;
  my $FROM_FILE = "No prior file";
  my $description = "Map (hash) file of old/new chromosome and scaffold IDs";
  ($printed_man_head, $printed_man_descr_head) = (0, 0);
  &write_manifest($TO_FILE, $FROM_FILE, $GNM_MAN, $description, "NULL");
}

##################################################
sub make_featid_map {
  if ($featid_map){ 
    say "featid_map has been provided, so don't calculate it";
    return 
  } 
  say "\n== Making a map (hash) of old/new gene IDs, to go to the annotations directory ==";
  # Get path to main GFF input file
  my $GFF_FILE_START = "";
  my $GFF_EXONS_FILE_START = "";
  my ($strip_regex, $STRIP_RX);

  unless (exists ${$confobj}{from_to_gff}){ 
    say "There is no from_to_gff block in the config, so no featid_map will be calculated.";
    say "Only a genome collection will be prepared.";
    return;
  }
  for my $fr_to_hsh (@{$confobj->{from_to_gff}}){ # Get the "strip" regex, if any, from the conf file
    if ($fr_to_hsh->{to} =~ /gene_models_main.gff3/){
      $GFF_FILE_START = 
        "$dir_hsh{work_dir}/$dir_hsh{from_annot_dir}/$prefix_hsh{from_annot_prefix}$fr_to_hsh->{from}";
      say "  There is a gff_main file: $prefix_hsh{from_annot_prefix}$fr_to_hsh->{from}";
      if ($fr_to_hsh->{strip}){
        $strip_regex = $fr_to_hsh->{strip};
        $strip_regex =~ s/["']//g; # Strip surrounding quotes if any. We'll add them below.
        $STRIP_RX=qr/$strip_regex/ 
      }
      else { $STRIP_RX=qr/$/ }
      say "  STRIP REGEX: \"$STRIP_RX\"";
    }
    elsif ($fr_to_hsh->{to} =~ /gene_models_exons.gff3/){
      $GFF_EXONS_FILE_START = 
        "$dir_hsh{work_dir}/$dir_hsh{from_annot_dir}/$prefix_hsh{from_annot_prefix}$fr_to_hsh->{from}";
      $strip_regex = $fr_to_hsh->{strip};
      say "  There is a gene_models_exons file: $prefix_hsh{from_annot_prefix}$fr_to_hsh->{from}";
    }
    else {
      say "Please ensure that the from_to_gff config block contains \"to: gene_models_main.gff3\"";  
    }
  }
  say "GFF_FILE_START: $GFF_FILE_START";
  unless (-e $GFF_FILE_START) {
    die "File $GFF_FILE_START doesn't exist. Check filename components in config file.\n"
  }
   
  my $GFF_IN_FH;
  say "Generating hash of old/new gene IDs.";
  if (-f $GFF_FILE_START && -f $GFF_EXONS_FILE_START){ # There are gene_models_main & gene_models_exons files
    open($GFF_IN_FH, "zcat $GFF_FILE_START $GFF_EXONS_FILE_START |") or die \
      "Can't do zcat $GFF_FILE_START $GFF_EXONS_FILE_START |: $!";
  }
  else { # There is only a gene_models_main file; not also a gene_models_exons file
    open($GFF_IN_FH, "zcat $GFF_FILE_START |") or die "Can't do zcat $GFF_FILE_START |: $!";
  }
  $FEATID_MAP = "$WD/annotations/$ANNCOL/$GENSP.$ANNCOL.featid_map.tsv";
  open (my $FEATID_MAP_FH, ">", $FEATID_MAP) or die "Can't open out $FEATID_MAP: $!\n";
  my %seen_feat_id;
  while (my $line = <$GFF_IN_FH>){
    chomp $line;
    next if ($line =~ /^#|^\s*$/);
    my @parts = split(/\t/, $line);
    next if (scalar(@parts)<9);
    my $feat_id = $parts[8];
    $feat_id =~ s/ID=([^;]+);?$/$1/; # ID is the only attribute in the 9th column
    $feat_id =~ s/ID=([^;]+);.+/$1/; # ID is one of several attributes in the 9th column
    my $new_feat_id = $feat_id;
    if (defined $strip_regex){
      $new_feat_id =~ s/$STRIP_RX//g;
    }
    unless ( $seen_feat_id{$feat_id} ) {
      $seen_feat_id{$feat_id}++;
      say $FEATID_MAP_FH "$feat_id\t$TO_ANN_PREFIX.$new_feat_id";
    }
  }

  my $TO_FILE = $FEATID_MAP;
  my $FROM_FILE = "No prior file";
  my $description = "Hash file of old/new gene IDs";
  ($printed_man_head, $printed_man_descr_head) = (0, 0);
  &write_manifest($TO_FILE, $FROM_FILE, $ANN_MAN, $description, "NULL");
}

##################################################
sub readme {
  say "\n== Writing README files ==";
  my @readme_keys = qw(identifier provenance source synopsis scientific_name taxid 
       scientific_name_abbrev genotype chromosome_prefix supercontig_prefix description 
       dataset_doi genbank_accession original_file_creation_date 
       local_file_creation_date dataset_release_date publication_doi publication_title 
       contributors citation data_curators public_access_level license keywords);
  
  $readme_hsh{scientific_name} = $scientific_name;
  $readme_hsh{scientific_name_abbrev} = $GENSP;
  
  # Assembly README
  open(my $GNM_README_FH, '>', $GNM_README) or die "Can't open out $GNM_README: $!";
  print $GNM_README_FH "---\n";
  $readme_hsh{identifier} = $GNMCOL;
  $readme_hsh{synopsis} = $readme_hsh{synopsis_genome};
  $readme_hsh{description} = $readme_hsh{description_genome};
  if ($readme_hsh{dataset_doi_genome}){$readme_hsh{dataset_doi} = "\"$readme_hsh{dataset_doi_genome}\""}
  else {$readme_hsh{dataset_doi} = ""}

  my %seen_genotype;
  for my $key (@readme_keys){
    if ($key =~ /provenance|source|description|synopsis|title|citation|date/ ){ # wrap in quotes
      #say "CHECK: $key: \"$readme_hsh{$key}\"\n";
      if ( $readme_hsh{$key} ){
        say $GNM_README_FH "$key: \"$readme_hsh{$key}\"\n";
      }
    }
    elsif ( $key =~ /genotype/ ){
      say $GNM_README_FH "$key:";
      for my $genotype (split(/, */, $readme_hsh{$key})){
        unless ($seen_genotype{$genotype}){
          say $GNM_README_FH "  - $genotype";
          $seen_genotype{$genotype}++;
        }
      }
      say $GNM_README_FH "";
    }
    else { # presume no quotes needed
      if ( $readme_hsh{$key} ){
        say $GNM_README_FH "$key: $readme_hsh{$key}\n";
      }
    }
  }

  # Assembly CHANGES
  open(my $GNM_CHANGES_FH, '>>', $GNM_CHANGES) or die "Can't open out $GNM_CHANGES: $!";
  say $GNM_CHANGES_FH "---";
  say $GNM_CHANGES_FH "  - $readme_hsh{local_file_creation_date} Initial repository creation, using ds_souschef.pl";

  # Annotation README
  open(my $ANN_README_FH, '>', $ANN_README) or die "Can't open out $ANN_README: $!";
  print $ANN_README_FH "---\n";
  $readme_hsh{identifier} = $ANNCOL;
  $readme_hsh{synopsis} = $readme_hsh{synopsis_annot};
  $readme_hsh{description} = $readme_hsh{description_annot};
  if ($readme_hsh{dataset_doi_annot}){$readme_hsh{dataset_doi} = "\"$readme_hsh{dataset_doi_annot}\""}
  else {$readme_hsh{dataset_doi} = ""}

  %seen_genotype = ();
  for my $key (@readme_keys){
    if ($key =~ /provenance|source|description|synopsis|title|citation|date/ ){ # wrap in quotes
      print_to_readme( $ANN_README_FH, $key, $readme_hsh{$key}, 1);
    }
    elsif ( $key =~ /genotype/ ){
      say $ANN_README_FH "$key:";
      for my $genotype (split(/, */, $readme_hsh{$key})){
        unless ($seen_genotype{$genotype}){
          say $ANN_README_FH "  - $genotype";
          $seen_genotype{$genotype}++;
        }
      }
      say $ANN_README_FH "";
    }
    else { # presume no quotes needed
      print_to_readme( $ANN_README_FH, $key, $readme_hsh{$key}, 0);
    }
  }

  # Annotation CHANGES
  open(my $ANN_CHANGES_FH, '>>', $ANN_CHANGES) or die "Can't open out $ANN_CHANGES: $!";
  say $ANN_CHANGES_FH "---";
  say $ANN_CHANGES_FH "  - $readme_hsh{local_file_creation_date} Initial repository creation, using ds_souschef.pl";
}

##################################################
sub ann_as_is {
  say "\n== Copying over \"as-is\" annotation information files, if present, unchanged ==";
  for my $fr_to_hsh (@{$confobj->{from_to_annot_as_is}}){ 
    my $FROM_FILE = "$WD/$dir_hsh{from_annot_dir}/$prefix_hsh{from_annot_prefix}$fr_to_hsh->{from}";
    my $TO_FILE = "$ANNDIR/$GENSP.$ANNCOL.$fr_to_hsh->{to}";

    &write_manifest($TO_FILE, $FROM_FILE, $ANN_MAN, $fr_to_hsh->{description}, "NULL" );

    say "Converting from ... to ...:\n  $FROM_FILE\n  $TO_FILE";
    if ($FROM_FILE =~ /gz$/){ 
      open(my $AS_IS_FROM_FH, "zcat $FROM_FILE |") or die "Can't do gunzip $FROM_FILE|: $!";
      open(my $AS_IS_TO_FH, ">", $TO_FILE) or die "Can't open out $TO_FILE: $!\n";
      while (<$AS_IS_FROM_FH>) {
        print $AS_IS_TO_FH $_;
      }
    } 
    else { # else file isn't gzipped, so just copy it
      copy($FROM_FILE, $TO_FILE) or die "Can't copy files: $!";
    }
  }
  if (defined $confobj->{original_readme_and_usage}){
    say "\n== Copying the original README and/or usage agreement files into the annotations directory ==";
    for my $fr_to_hsh (@{$confobj->{original_readme_and_usage}}){ 
      my $FROM_FILE = "$WD/$dir_hsh{from_annot_dir}/$fr_to_hsh->{from_full_filename}";
      my $TO_FILE = "$ANNDIR/$GENSP.$ANNCOL.$fr_to_hsh->{to}";
      &write_manifest($TO_FILE, $FROM_FILE, $ANN_MAN, $fr_to_hsh->{description}, "NULL" );

      say "Converting from ... to ...:\n  $FROM_FILE\n  $TO_FILE";
      copy($FROM_FILE, $TO_FILE) or die "Can't copy files: $!"; # Should be uncompressed text files
    }
  }
}

##################################################
sub gnm_as_is {
  say "\n== Copying over \"as-is\" genome information files, if present, unchanged ==";
  for my $fr_to_hsh (@{$confobj->{from_to_genome_as_is}}){ 
    my $FROM_FILE = "$WD/$dir_hsh{from_genome_dir}/$prefix_hsh{from_genome_prefix}$fr_to_hsh->{from}";
    my $TO_FILE = "$GNMDIR/$GENSP.$GNMCOL.$fr_to_hsh->{to}";

    say "Converting from ... to ...:\n  $FROM_FILE\n  $TO_FILE";
    &write_manifest($TO_FILE, $FROM_FILE, $GNM_MAN, $fr_to_hsh->{description}, "NULL" );

    if ($FROM_FILE =~ /gz$/){
      open(my $AS_IS_FROM_FH, "zcat $FROM_FILE |") or die "Can't do gunzip $FROM_FILE|: $!";
      open(my $AS_IS_TO_FH, ">", $TO_FILE) or die "Can't open out $TO_FILE: $!\n";
      while (<$AS_IS_FROM_FH>) {
        print $AS_IS_TO_FH $_;
      }
    } 
    else { # else file isn't gzipped, so just copy it
      copy($FROM_FILE, $TO_FILE) or die "Can't copy files: $!";
    }
  }
  if (defined $confobj->{original_readme_and_usage}){
    say "\n== Copying the original README and/or usage agreement files into the genomes directory ==";
    for my $fr_to_hsh (@{$confobj->{original_readme_and_usage}}){ 
      my $FROM_FILE = "$WD/$dir_hsh{from_genome_dir}/$fr_to_hsh->{from_full_filename}";
      my $TO_FILE = "$GNMDIR/$GENSP.$GNMCOL.$fr_to_hsh->{to}";
      &write_manifest($TO_FILE, $FROM_FILE, $GNM_MAN, $fr_to_hsh->{description}, "NULL" );

      say "Converting from ... to ...:\n  $FROM_FILE\n  $TO_FILE";
      copy($FROM_FILE, $TO_FILE) or die "Can't copy files: $!"; # Should be uncompressed text files
    }
  }
}

##################################################
sub cds {
  say "\n== Processing the gene nucleotide files (CDS, mRNA) ==";
  for my $fr_to_hsh (@{$confobj->{from_to_cds_mrna}}){ 
    my $FROM_FILE = "$WD/$dir_hsh{from_annot_dir}/$prefix_hsh{from_annot_prefix}$fr_to_hsh->{from}"; 
    my $TO_FILE = "$ANNDIR/$GENSP.$ANNCOL.$fr_to_hsh->{to}";

    my $APPS = $fr_to_hsh->{applications};
    unless (defined $APPS){ $APPS = "NULL" }
    &write_manifest($TO_FILE, $FROM_FILE, $ANN_MAN, $fr_to_hsh->{description}, $APPS );

    say "Converting from ... to ...:\n  $FROM_FILE\n  $TO_FILE";
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
    say "  Execute hash_into_fasta_id.pl $ARGS";
    system("hash_into_fasta_id.pl $ARGS");
  }
}

##################################################
sub protein {
  say "\n== Processing the protein sequence files ==";
  for my $fr_to_hsh (@{$confobj->{from_to_protein}}){ 
    my $FROM_FILE = "$WD/$dir_hsh{from_annot_dir}/$prefix_hsh{from_annot_prefix}$fr_to_hsh->{from}"; 
    my $TO_FILE = "$ANNDIR/$GENSP.$ANNCOL.$fr_to_hsh->{to}";

    my $APPS = $fr_to_hsh->{applications};
    unless (defined $APPS){ $APPS = "NULL" }
    &write_manifest($TO_FILE, $FROM_FILE, $ANN_MAN, $fr_to_hsh->{description}, $APPS );

    say "Converting from ... to ...:\n  $FROM_FILE\n  $TO_FILE";
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
    say "  Execute hash_into_fasta_id.pl $ARGS";
    system("hash_into_fasta_id.pl $ARGS");
  }
}

##################################################
sub gff {
  say "\n== Processing the GFF files ==";
  for my $fr_to_hsh (@{$confobj->{from_to_gff}}){ 
    my $FROM_FILE = "$WD/$dir_hsh{from_annot_dir}/$prefix_hsh{from_annot_prefix}$fr_to_hsh->{from}"; 
    my $TO_FILE = "$ANNDIR/$GENSP.$ANNCOL.$fr_to_hsh->{to}";

    my $APPS = $fr_to_hsh->{applications};
    unless (defined $APPS){ $APPS = "NULL" }
    &write_manifest($TO_FILE, $FROM_FILE, $ANN_MAN, $fr_to_hsh->{description}, $APPS );

    say "Converting from ... to ...:\n  $FROM_FILE\n  $TO_FILE";
    my $ARGS;
    my $GFF_STRIP_RX = "$GENSP.$ANN_GT_VER."; # Prefix to strip from the full-yuck name, e.g. glyma.Wm82.gnm2.ann1. 
    say "  STRIP REGEX for Name attribute in GFF: \"$GFF_STRIP_RX";
    $ARGS = "-gff $FROM_FILE -featid_map $FEATID_MAP -seqid_map $SEQID_MAP -sort -strip \"$GFF_STRIP_RX\" -out $TO_FILE";
    say "  Execute hash_into_gff_id.pl $ARGS";
    system("hash_into_gff_id.pl $ARGS");
    if ($fr_to_hsh->{to} =~ /gene_models_main.gff3/) {
      say "  Generating CDS bed file from GFF";
      my $bed_file = $TO_FILE;
      $bed_file =~ s/gene_models_main.gff3/gene_models_main.bed/;
      my $gff_to_bed_command = "cat $TO_FILE | gff_to_bed7_mRNA.awk | sort -k1,1 -k2n,2n > $bed_file";
      `$gff_to_bed_command`; # or die "system call of gff_to_bed7_mRNA.awk failed: $?";
      my $description = "BED-format file, derived from gene_models_main.gff3";
      &write_manifest($bed_file, $FROM_FILE, $ANN_MAN, $description, "NULL" );
    }
  }
}

##################################################
sub gff_as_is {
  say "\n== Copying over \"as-is\" gff files, if present, unchanged ==";
  for my $fr_to_hsh (@{$confobj->{from_to_gff_as_is}}){ 
    my $FROM_FILE = "$WD/$dir_hsh{from_annot_dir}/$prefix_hsh{from_annot_prefix}$fr_to_hsh->{from}";
    my $TO_FILE = "$ANNDIR/$GENSP.$ANNCOL.$fr_to_hsh->{to}";

    my $APPS = $fr_to_hsh->{applications};
    unless (defined $APPS){ $APPS = "NULL" }
    &write_manifest($TO_FILE, $FROM_FILE, $ANN_MAN, $fr_to_hsh->{description}, $APPS );

    say "Converting from ... to ...:\n  $FROM_FILE\n  $TO_FILE";
    if ($FROM_FILE =~ /gz$/){ 
      open(my $AS_IS_FROM_FH, "zcat $FROM_FILE |") or die "Can't do gunzip $FROM_FILE|: $!";
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
sub assembly {
  say "\n== Processing the genome assembly files ==";
  for my $fr_to_hsh (@{$confobj->{from_to_genome}}){ 
    my $FROM_FILE = "$WD/$dir_hsh{from_genome_dir}/$prefix_hsh{from_genome_prefix}$fr_to_hsh->{from}";
    my $TO_FILE = "$GNMDIR/$GENSP.$GNMCOL.$fr_to_hsh->{to}";

    my $APPS = $fr_to_hsh->{applications};
    unless (defined $APPS){ $APPS = "NULL" }
    &write_manifest($TO_FILE, $FROM_FILE, $GNM_MAN, $fr_to_hsh->{description}, $APPS );

    say "Converting from ... to ...:\n  $FROM_FILE\n  $TO_FILE";
    my $ARGS = "-hash $SEQID_MAP -fasta $FROM_FILE -nodef -out $TO_FILE";
    say "  Execute hash_into_fasta_id.pl $ARGS";
    system("hash_into_fasta_id.pl $ARGS");
  }
}

##################################################
sub pangene_tsv {
  say "\n== Processing the pangene tabular files ==";
  for my $fr_to_hsh (@{$confobj->{from_to_pan_tsv}}){ 
    my $FROM_FILE = "$WD/$dir_hsh{from_pan_dir}/$fr_to_hsh->{from}";
    my $TO_FILE = "$PANDIR/$PANCOL.$fr_to_hsh->{to}";

    my $APPS = $fr_to_hsh->{applications};
    unless (defined $APPS){ $APPS = "NULL" }
    &write_manifest($TO_FILE, $FROM_FILE, $PAN_MAN, $fr_to_hsh->{description}, $APPS );

    say "Converting from ... to ...:\n  $FROM_FILE\n  $TO_FILE";
    my $PAN_RX = qr/$TO_PAN_PREFIX/;
    open (my $FROM_FH, "<", $FROM_FILE) or die "Can't open in $FROM_FILE: $!\n";
    open (my $TO_FH, ">", $TO_FILE) or die "Can't open out $TO_FILE: $!\n";
    while (<$FROM_FH>){
      my $line = $_;
      $line =~ s/^pan/$TO_PAN_PREFIX.pan/;
      print $TO_FH $line;
    } 
  }
}

##################################################
sub pangene_fasta {
  say "\n== Processing the pangene fasta files ==";
  for my $fr_to_hsh (@{$confobj->{from_to_pan_fasta}}){ 
    my $FROM_FILE = "$WD/$dir_hsh{from_pan_dir}/$fr_to_hsh->{from}";
    my $TO_FILE = "$PANDIR/$PANCOL.$fr_to_hsh->{to}";

    my $APPS = $fr_to_hsh->{applications};
    unless (defined $APPS){ $APPS = "NULL" }
    &write_manifest($TO_FILE, $FROM_FILE, $PAN_MAN, $fr_to_hsh->{description}, $APPS );

    say "Converting from ... to ...:\n  $FROM_FILE\n  $TO_FILE";
    my ($strip_regex, $STRIP_RX);
    if ($fr_to_hsh->{strip}){
      $strip_regex = $fr_to_hsh->{strip};
      $strip_regex =~ s/["']//g; # Strip surrounding quotes if any. We'll add them below.
      $STRIP_RX=qr/$strip_regex/;
      say "  STRIP REGEX: \"$STRIP_RX\"";
    }
    else { $STRIP_RX=qr/$/ }

    open (my $FROM_FH, "<", $FROM_FILE) or die "Can't open in $FROM_FILE: $!\n";
    open (my $TO_FH, ">", $TO_FILE) or die "Can't open out $TO_FILE: $!\n";
    while (<$FROM_FH>){
      my $line = $_;
      if ($strip_regex){
        $line =~ s/>$STRIP_RX/>$TO_PAN_PREFIX./;
      }
      else {
        $line =~ s/>/>$TO_PAN_PREFIX./;
      }
      print $TO_FH $line;
    } 
  }
}

##################################################
sub pangene_as_is {
  say "\n== Processing the pangene fasta files ==";
  for my $fr_to_hsh (@{$confobj->{from_to_pan_as_is}}){ 
    my $FROM_FILE = "$WD/$dir_hsh{from_pan_dir}/$fr_to_hsh->{from}";
    my $TO_FILE = "$PANDIR/$PANCOL.$fr_to_hsh->{to}";

    my $APPS = $fr_to_hsh->{applications};
    unless (defined $APPS){ $APPS = "NULL" }
    &write_manifest($TO_FILE, $FROM_FILE, $PAN_MAN, $fr_to_hsh->{description}, $APPS );

    say "Converting from ... to ...:\n  $FROM_FILE\n  $TO_FILE";
    copy($FROM_FILE, $TO_FILE) or die "Can't copy files: $!";
  }
}

##################################################
sub pangene_readme {
  say "\n== Writing pangene README file ==\n";
  my @readme_keys = qw(identifier provenance source synopsis scientific_name taxid 
       annotations_main annotations_extra description bioproject sraproject dataset_doi genbank_accession 
       original_file_creation_date local_file_creation_date dataset_release_date publication_doi 
       publication_title contributors citation data_curators public_access_level license keywords);
  
  $readme_hsh{scientific_name} = $scientific_name;
  
  # Pangene README
  open(my $PAN_README_FH, '>', $PAN_README) or die "Can't open out $PAN_README: $!";
  binmode($PAN_README_FH, ':utf8');
  print $PAN_README_FH "---\n";
  $readme_hsh{identifier} = $PANCOL;
  $readme_hsh{synopsis} = $readme_hsh{synopsis};
  $readme_hsh{description} = $readme_hsh{description};
  if ($readme_hsh{dataset_doi}){$readme_hsh{dataset_doi} = "\"$readme_hsh{dataset_doi}\""}
  else {$readme_hsh{dataset_doi} = ""}
  if ($readme_hsh{annotations_extra}){$readme_hsh{annotations_extra} = "\"$readme_hsh{annotations_extra}\""}
  else {$readme_hsh{annotations_extra} = ""}
  my %seen_annot_main;
  my %seen_annot_extra;
  for my $key (@readme_keys){
    if ($key =~ /provenance|source|description|synopsis|title|citation|date/ ){ # wrap in quotes
      print_to_readme( $PAN_README_FH, $key, $readme_hsh{$key}, 1 );
    }
    elsif ( $key =~ /annotations_main/ ){
      say $PAN_README_FH "$key:";
      for my $annot (split(/, */, $readme_hsh{$key})){
        unless ($seen_annot_main{$annot}){
          say $PAN_README_FH "  - $annot";
          $seen_annot_main{$annot}++;
        }
      }
      say $PAN_README_FH "";
    }
    elsif ( $key =~ /annotations_extra/ ){
      say $PAN_README_FH "$key:";
      for my $annot (split(/, */, $readme_hsh{$key})){
        unless ($seen_annot_extra{$annot}){
          say $PAN_README_FH "  - $annot";
          $seen_annot_extra{$annot}++;
        }
      }
      say $PAN_README_FH "";
    }
    else { # presume no quotes needed
      print_to_readme( $PAN_README_FH, $key, $readme_hsh{$key}, 0 );
    }
  }

  # Pangene CHANGES
  open(my $PAN_CHANGES_FH, '>>', $PAN_CHANGES) or die "Can't open out $PAN_CHANGES: $!";
  say $PAN_CHANGES_FH "---";
  say $PAN_CHANGES_FH "  - $readme_hsh{local_file_creation_date} Initial repository creation, using ds_souschef.pl";
}

##################################################
sub print_to_readme {
  my ($FH, $key, $value, $quote) = @_;
  unless($value){
    $value = "";
  }

  if (length($value) > 0 && $quote == 1){
    say $FH "$key: \"$value\"\n";
  }
  elsif (length($value) > 0 && $quote == 0){
    say $FH "$key: $value\n";
  }
  elsif (length($value) == 0){
    #say $FH "$key: \n";
    # Do nothing, since there is no value.
  }
}

sub write_manifest {
  my ($TO_FILE, $FROM_FILE, $MAN_FILE, $description, $applications) = @_;
  my $to_name_base = basename($TO_FILE);
  my $from_name_base = basename($FROM_FILE);

  open (my $MAN_OFH, ">>", $MAN_FILE) or die "Can't open out $MAN_FILE: $!";
  open (my $MAN_IFH, "<", $MAN_FILE) or die "Can't open in $MAN_FILE: $!";

  # Don't print redundant lines (which might happen in multiple runs, if "-extend" is set
  my (%seen_to_file);
  while (<$MAN_IFH>){ 
    chomp;
    my $filename = $_;
    $filename =~ s/^(\S+).gz: .+/$1/;
    $filename =~ s/^(\S+): .+/$1/;
    #say "  seen MAN_FILE: $filename";
    $seen_to_file{$filename}++ if ($filename =~ $to_name_base);
    if ($. == 1 && $_ =~ /^---/){ $printed_man_head++ }
  }

  unless ($printed_man_head){
    say $MAN_OFH "---";
    $printed_man_head++;
  }
  
  unless ($seen_to_file{$to_name_base}){
    my $separator;
    if ( $to_name_base =~ /readme.txt|html/ ){ $separator = ":" }
    else { $separator = ".gz:" }
    say $MAN_OFH "- name: $to_name_base$separator";
    say $MAN_OFH "  description: $description";
    say $MAN_OFH "  prior_names:";
    say $MAN_OFH "   - $from_name_base";
    if ($applications !~ /NULL/){
      say $MAN_OFH "  applications:";
      for my $app (@{$applications}){
        say $MAN_OFH "   - $app";
      }
    }
  }
}

__END__

Steven Cannon
Versions
2022-10-24 New named script, "ds_souschef_id_map.pl", deriving from 2022-10-17 ds_souschef_genomic.pl
           The main difference is that ..._id_map.pl uses full hash/map of all features, whereas 
           ..._genomic.pl uses just mapping files with the base gene IDs, excluding splice forms and subfeatures.
           Also, handling of original readme and usage files is more flexible (entailing a change in the config).
2022-11-12 Renamed from ds_souschef_id_map.pl to ds_souschef.pl, just for the simplification.
           Change use of strip_regex in make_featid_map, applying it only to the new name (col 2).
2022-11-15 Fixed component existence-check for subroutines ann_as_is and gnm_as_is.
2022-11-27 Add CHANGES files to annotations and genomes collections.
2022-12-18 Add flag "-SHash" to allow an initial mapping of old/new chromosome & scaffold IDs, e.g. 
                   CM012345.1  Chr01
2023-02-01 Major new version; now handles pangene collections. 
2023-02-02 Handle coll_genotype for the collection name (e.g. "mixed") and multi-element genotype for the README.
2023-02-07 Remove quotes from README when there is no value. 
             For pangene README, replace genotype with annotations_main and annotations_extra.
2023-02-08 Remove scientific_name_abbrev from pangene README
2023-03-04 In make_featid_map, handle features in which the 9th column has only one attribute, e.g. ID=Identifier
2023-03-18 Permit more variation in GFF filename
2023-06-09 Handle genomes README keys supercontig_prefix and chromosome_prefix 
2023-11-27 Change from gff_to_bed6_mRNA.awk to gff_to_bed7_mRNA.awk
2024-01-09 Change name of bed file from cds.bed to gene_models_main.bed
2024-04-19 Add back scientific_name_abbrev for README, and add gff_as_is function to handle noncoding gffs 
2024-04-22 Bug fix: call gff_as_is subroutine!
2024-12-09 Write single combined MANIFEST file rather than separate correspondence and description files
2025-01-13 Switch to zcat from gzcat.
2024-02-09 Check if from_to_gff exists in config; if not, don't make annotation collection
2025-04-07 When making gff featid map, handle case where ID is the only attribute in the 9th column, with or without semicolon
2026-01-28 Handle missing annotations_extra

