# Objective: Prepare assembly collection for Apios priceana accession MO19963523
# Note: characteristics of this job include "genomes" only, no annotation; and the assembly resolved into two haplotypes.
# The assembly is from HudsonAlpha.
# Started on 2025-02-07

# See the document here for detailed (general) instructions:
#   https://github.com/legumeinfo/datastore-specifications/tree/main/PROTOCOLS/README.md

cat << DONT_RUN_ME
This file contains notes for creating genome and annotation collections for the Data Store. Read them critically, 
revise for your particular job, and copy-paste in an interactive terminal session. The file has a suffix ".sh" 
only to get syntax highlighting in an editor (e.g. vim). It should not be executied as a shell script.
DONT_RUN_ME
echo; exit 1;

<< REFERENCE
REFERENCE

# NOTE: utility scripts are at 
# If not added already to the PATH, do:
    PATH=/project/legume_project/datastore/datastore-specifications/scripts:$PATH 

# Variables for this job
  PRIVATE=/project/legume_project/datastore/private   # Set this to the Data Store private root directory, i.e. ...data/private/
  STRAIN=MO19963523
  GENUS=Apios
  SP=priceana
  GENSP=apipr
  GNM=gnm1
  ANN=ann1  
  GENOME=Apios.priceana # The filename prefix common among all genome files in the source
  ANNOTATION=Apios.priceana # The filename prefix ommon among all annotation files in the source
  CONFIGDIR=/project/legume_project/datastore/datastore-specifications/scripts/ds_souschef_configs


# NOTE: Get the keys with register_key.pl below !
  GKEY=814V
  AKEY=P2VZ

# Register new keys at /project/legume_project/datastore/datastore-registry
# NOTE: Remember to fetch and pull before generating new keys.
  cd /project/legume_project/datastore/datastore-registry
  ./register_key.pl -v "$GENUS $SP genomes $STRAIN.$GNM"
  ./register_key.pl -v "$GENUS $SP annotations $STRAIN.$GNM.$ANN"
# NOTE: Remember to add, commit, and push the updated ds_registry.tsv  

# Make and cd into a work directory
  mkdir -p $PRIVATE/$GENUS/$SP/$STRAIN.$GNM.$ANN
  cd $PRIVATE/$GENUS/$SP/$STRAIN.$GNM.$ANN

# Download the assembly and annotation files into "original".

 mkdir original derived

 zcat original/Apios_priceana_hifiasm.hap1.FINAL.fasta.gz | 
   awk '$1 ~ /_[0-9]$/ {print ">Chr0" substr($1,length($1),1)}
        $1 ~ /_10$|_11$/ {print ">Chr" substr($1,length($1)-1,2)}
        $1 !~ /_[0-9]$|_10$|_11$/ {print}' > derived/Apios.priceana.hap1.fna

# Check the files. If the assembly sequence is not wrappeed (to permit indexing), fix this.
# Also check the form of the chromosome and scaffold names. 

<< ASSESS
Based on initial comparisons with Apios americana,
Reverse-complement these from priceana:
  Chr01  Chr02  Chr05  Chr08  Chr11

These pairs are non-matching:
  Chr04-Chr04  Chr06-Chr06
Rename, under the assumption that each is the other's missing matche
  Chr04 ==> Chr06new   Chr06 ==> Chr04new
ASSESS

# Split pseudomolecules into separate files
  cd derived

  mkdir 00_scaffs 00_chr
  
  split_fasta_to_files_by_name.pl -in Apios.priceana.hap1.fna -out 00_scaffs
  
  cp 00_scaffs/* 00_chr/

  revcomp.pl -in 00_scaffs/Chr01 > 00_chr/Chr01 & 
  revcomp.pl -in 00_scaffs/Chr02 > 00_chr/Chr02 & 
  revcomp.pl -in 00_scaffs/Chr05 > 00_chr/Chr05 & 
  revcomp.pl -in 00_scaffs/Chr08 > 00_chr/Chr08 & 
  revcomp.pl -in 00_scaffs/Chr11 > 00_chr/Chr11 &
  
    # Take care with the line width. The default is 100, which does match the other chromosomes.
  
# Swap Chr04 and Chr06 and reverse-complement
  revcomp.pl -in 00_scaffs/Chr04 | perl -pe 's/Chr04/Chr06/' > 00_chr/Chr06
  revcomp.pl -in 00_scaffs/Chr06 | perl -pe 's/Chr06/Chr04/' > 00_chr/Chr04


# Generate a new genome file (destructive)
  cat 00_chr/* > Apios.priceana.hap1.fna
    rm -rf 00*
  
  cd ..
  gzip derived/Apios.priceana.hap1.fna &

# Then run ds_souschef.pl again

# There are currently no annotations for Apios, so skip any annotation steps ...  


## Compress annotation_info and defline  text files in annotations
#  gzip $PZVER/annotation/*annotation_info.txt
#  gzip $PZVER/annotation/*defline.txt
#
#  gzip $PZVER/annotation/$ANNOTATION.locus_transcript_name_map.txt

# Prepare the config for ds_souschef. Typically, copy from a similar config file and revise.
  vim $CONFIGDIR/$GENSP.$STRAIN.$GNM.$ANN.yml

# Run ds_souschef.pl with the config above
  ds_souschef.pl -config $CONFIGDIR/$GENSP.$STRAIN.$GNM.$ANN.yml

# NOTE: Check the results for sanity. 
# The fasta files (cds, transcript, protein) should all have prefixes (gensp.genotype.gnm#.ann#.)
# If there are any cases of "HASH UNDEFINED", then check whether the gff "strip" step produced
# the desired result. If not (if the Phytozome version suffix is still present), check that 
# $PZVER is correct and was exported.  
  echo "Testing for hashing correctness. Counts of UNDEFINED should be 0 in all files."
  grep -c UNDEFINED annotations/$STRAIN.$GNM.$ANN.$AKEY/*

# In the working directory, validate the READMEs and correct (upstream, in the ds_souschef yml) if necessary
  validate.sh readme annotations/$STRAIN.$GNM.$ANN.$AKEY/README*
  validate.sh readme genomes/$STRAIN.$GNM.$GKEY/README*

# Compress and index
  compress_and_index.sh annotations/$STRAIN.$GNM.$ANN.$AKEY &
  compress_and_index.sh genomes/$STRAIN.$GNM.$GKEY &
  wait

# Calculate md5sum
  mdsum-folder.bash annotations/$STRAIN.$GNM.$ANN.$AKEY
  mdsum-folder.bash genomes/$STRAIN.$GNM.$GKEY

# Move to annex, for next steps by Andrew (AHRD and BUSCO)
  mkdir -p /project/legume_project/datastore/annex/$GENUS/$SP/annotations/
  mkdir -p /project/legume_project/datastore/annex/$GENUS/$SP/genomes/

  mv annotations/$STRAIN.$GNM.$ANN.$AKEY /project/legume_project/datastore/annex/$GENUS/$SP/annotations/
  mv genomes/$STRAIN.$GNM.$GKEY /project/legume_project/datastore/annex/$GENUS/$SP/genomes/

# Push the ds_souschef config to GitHub
  cd $CONFIGDIR
  git status  # etc.

