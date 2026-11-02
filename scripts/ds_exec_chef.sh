#!/usr/bin/env bash

set -o errexit -o errtrace -o nounset -o pipefail -o posix

trap 'echo ${0##*/}:${LINENO} ERROR executing command: ${BASH_COMMAND}' ERR

# to help assign a heredoc value to a variable. The internal line return is intentional.
define(){ o=; while IFS=$'\n' read -r a; do o="$o$a"'
'; done; eval "$1=\$o"; }

define HELP_DOC <<'EOS'
NAME
  ds_exec_chef.sh  -- Coordinate the preparation of genomic data collections for the 
    SoyBase/LegumeInfo/PeanutBase datastore. The script takes variables from a yaml-format config file, 
    and calls the script ds_souschef.pl to parepare a set of files in two collections of genomic data:
    one collection of gene annotations (sequence files and GFF-format coordinates and information) 
    and associated metadata, and another collection containing a genome assembly and associated metadata.

SYNOPSIS
  gfa.sh -c CONFIG.yml

  Required:
           -l  - path to list of file paths to compressed (.gz) fasta files
           -c  - path to the ds_souschef config file
           -g  - name of the original genome file (uncompressed)
           -a  - name of the original annotation/gff file (uncompressed)
  Options: -h  - help

AUTHOR
    Steven Cannon <steven.cannon@usda.gov>
EOS

echo "THIS SCRIPT IS A WORK IN PROGRESS. IT IS NOT YET READY FOR PRODUCTION!" && exit 1

if [ "$#" -eq 0 ]; then
  echo >&2 "$HELP_DOC" && exit 0;
fi


# Command-line interpreter
config="null"
genome_orig="null"
annot_orig="null"

while getopts "c:a:g:h" opt
do
  case $opt in
    c) config=$OPTARG; echo "config: $config" ;;
    g) genome_orig=$OPTARG; echo "genome_orig: $genome_orig" ;;
    a) annot_orig=$OPTARG; echo "annot_orig: $annot_orig" ;;
    h) echo >&2 "$HELP_DOC" && exit 0 ;;
    *) echo >&2 echo "$HELP_DOC" && exit 1 ;;
  esac
done

if [[ "$config" == "null" ]]; then
  printf "\nPlease provide the path to the config file, e.g. -c config/gfa.conf\n" >&2
  exit 1;
fi

if [[ "$genome_orig" == "null" ]]; then
  printf "\nPlease provide the name of the original genome assembly, in the directory \"original\"\n" >&2
  exit 1;
fi

if [[ "$annot_orig" == "null" ]]; then
  printf "\nPlease provide the name of the original annotation file, in the directory \"original\"\n" >&2
  exit 1;
fi

cat_or_zcat() {
  case ${1} in
    *.gz) gzip -dc "$@" ;;
       *) cat "$@" ;;
  esac
}

# Add shell variables from config file
# shellcheck source=/dev/null
. "${config}"

# Variables for this job
# Standard paths
PRIVATE="/project/legume_project/datastore/private" # Set this to the Data Store private root directory, i.e. ...data/private
CONFIGDIR="/project/legume_project/datastore/datastore-specifications/scripts/ds_souschef_configs"
FROM="original"
TO="derived"

# From the ds_souschef_config
STRAIN="$coll_genotype"
GENUS="$genus"
SP="$species"
GENSP=$scientific_name_abbrev
GNM="$gnm_ver"
ANN="$ann_ver"
GENOME="$genome_orig"
ANNOTATION="$annot_orig"
GKEY="$genome_key"
AKEY="$annot_key"

ANN_TRANSFORM="$X"
GNM_TRANSFORM="$Y"

# Make and cd into a work directory
mkdir -p $PRIVATE/$GENUS/$PAN_GROUP/$STRAIN.$GNM.$ANN
cd $PRIVATE/$GENUS/$PAN_GROUP/$STRAIN.$GNM.$ANN
mkdir $FROM $TO

# Check for the existence of the genome and annotation files
if [[ -f "original/$genome_orig" ]]; then
  echo "The genome file original/$genome_orig exists and will be processed."
else 
  echo "The expected genome file does not exist at $PRIVATE/$GENUS/$SP/original/$genome_orig"
fi

if [[ -f "original/$annot_orig" ]]; then
  echo "The genome file original/$annot_orig exists and will be processed."
else 
  echo "The expected genome file does not exist at $PRIVATE/$GENUS/$SP/original/$annot_orig"
fi

# Prepare the data here:
cd $PRIVATE/$GENUS/$PAN_GROUP/$STRAIN.$GNM.$ANN

# Copy the fasta file to the derived directory
cat_or_zcat $FROM/$genome_orig > $TO/$STRAIN.fasta

  cat $FROM/$STRAIN.gff3 | simplify_genbank_gff.sh |
    perl -ne '@line= split("\t", $_); 
      if ($line[2] =~ /mRNA/) {
        $line[8] =~ s/ID=(.+)\.mRNA;(Parent=.+);Name=.+/ID=$1.1;$2;Name=$1.1/; 
        $new_line_m=join("\t",  @line); 
        print "$new_line_m" 
      }
      elsif ($line[2] =~ /exon/ && $line[1] =~ /./) {
        $line[8] =~ s/ID=exon-(.+)\.mRNA\.(.+);Parent=.+/ID=$1.1.$2;Parent=$1.1;Name=$1.1.$2/; 
        $new_line_e1=join("\t",  @line); 
        print "$new_line_e1" 
      }
      elsif ($line[2] =~ /CDS/ && $line[1] =~ /./) {
        $line[8] =~ s/ID=(cds)\.(.+)\.mRNA-(.+);Parent=.+/ID=$2.1.$1$3;Parent=$2.1;Name=$2.1.$1$3/; 
        $new_line_d1=join("\t",  @line); 
        print "$new_line_d1" 
      }
      elsif ($line[2] =~ /UTR/) {
        $line[8] =~ s/ID=(.+)\.mRNA\.(.+);Parent=.+/ID=$1.1.$2;Parent=$1.1;Name=$1.1.$2/; 
        $new_line_u=join("\t",  @line); 
        print "$new_line_u"
      }
      else {
        $new_line =join("\t",  @line); 
        print "$new_line"
      }' | 
    perl -pe 's/exon-//gc; s/\.mRNA/.1/; s/\.(cds\d+)-1/.1.$1/g' | 
    sort_gff.pl > $TO/$STRAIN.mod.gff3

# Use gffread to derive protein, CDS, and transcript files; then separate GFF into coding and noncoding
# based on list of protein-coding genes.
  
  cd $TO

  gffread -g $STRAIN.fasta \
          -w $STRAIN.transcript.fna \
          -x $STRAIN.CDS.fna \
          -y $STRAIN.protein.faa \
             $STRAIN.mod.gff3

# Derive bed file
  cat $STRAIN.mod.gff3 | gff_to_bed7_mRNA.awk | sort -k1,1 -k2n,2n > $STRAIN.mod.bed

# Derive primary/longest CDS, transcript, and protein sequences
  cat $STRAIN.CDS.fna | longest_variant_from_fasta.sh > $STRAIN.CDS_primary.fna
  cat $STRAIN.protein.faa | longest_variant_from_fasta.sh > $STRAIN.protein_primary.faa
  cat $STRAIN.transcript.fna | longest_variant_from_fasta.sh > $STRAIN.transcript_primary.fna

# Compress the files

  for file in *gff *f?a *bed *fasta; do
    bgzip -l9 $file &
  done
  wait

  rm *fai

# Split gff into coding and noncoding genes

# cd back to the main work directory
  cd $PRIVATE/$GENUS/$PAN_GROUP/$STRAIN.$GNM.$ANN

# Prepare the config for ds_souschef, in the datastore-specifications/scripts/ds_souschef_configs directory
  vim $CONFIGDIR/$PAN_GROUP/$GENSP.$STRAIN.$GNM.$ANN.yml

# Run ds_souschef.pl with the config above
  ds_souschef.pl -config $CONFIGDIR/$PAN_GROUP/$GENSP.$STRAIN.$GNM.$ANN.yml

# NOTE: Check the results for sanity.
# The fasta files (cds, transcript, protein) should all have prefixes (gensp.genotype.gnm#.ann#.)
  cd $PRIVATE/$GENUS/$PAN_GROUP/$STRAIN.$GNM.$ANN

  echo "Testing for hashing correctness. Counts of UNDEFINED should be 0 in all files."
  grep -c UNDEFINED annotations/$STRAIN.$GNM.$ANN.$AKEY/*

# In the working directory, validate the READMEs and correct (upstream, in the ds_souschef yml) if necessary

  validate.sh readme annotations/$STRAIN.$GNM.$ANN.$AKEY/README*
  validate.sh readme genomes/$STRAIN.$GNM.$GKEY/README*

# Also check MANIFESTs
  yamllint annotations/$STRAIN.$GNM.$ANN.$AKEY/MAN*yml
  yamllint genomes/$STRAIN.$GNM.$GKEY/MAN*yml

# Compress and index
  compress_and_index.sh annotations/$STRAIN.$GNM.$ANN.$AKEY
  compress_and_index.sh genomes/$STRAIN.$GNM.$GKEY

## Calculate md5sum
#  mdsum-folder.bash annotations/$STRAIN.$GNM.$ANN.$AKEY
#  mdsum-folder.bash genomes/$STRAIN.$GNM.$GKEY

# Move to annex, for next steps by Andrew (AHRD and BUSCO)
                                                             mkdir -p /project/legume_project/datastore/annex/$GENUS/$SP/annotations/
  mkdir -p /project/legume_project/datastore/annex/$GENUS/$SP/genomes/

  mv annotations/$STRAIN.$GNM.$ANN.$AKEY /project/legume_project/datastore/annex/$GENUS/$SP/annotations/
  mv genomes/$STRAIN.$GNM.$GKEY /project/legume_project/datastore/annex/$GENUS/$SP/genomes/

# Push the ds_souschef config to GitHub
