# Objective: Prepare assembly and annotation collection for Phaseolus coccineus accession PHA8298
# Started on 2024-02-09

# See the document here for detailed (general) instructions:
#   https://github.com/legumeinfo/datastore-specifications/tree/main/PROTOCOLS/README.md

cat << DONT_RUN_ME
NOTE: This file contains notes about creation of files for genome and annotation collections for the Data Store.
The notes are meant to be read critically, revised if necessary, and copy-pasted in an interactive terminal session.
The file has a suffix ".sh" merely in order to get syntax highlighting in an editor (e.g. vim).
The file is NOT expected to be runnable as a shell script.
DONT_RUN_ME
echo; exit 1;

<< REFERENCE
Guerra-García A, Rojas-Barrera IC, Ross-Ibarra J, Papa R, Piñero D. The genomic signature of wild-to-crop introgression during the domestication of scarlet runner bean (Phaseolus coccineus L.). Evol Lett. 2022 Jun 15;6(4):295-307. doi: 10.1002/evl3.285. PMID: 35937471; PMCID: PMC9346085.
REFERENCE


# NOTE: utility scripts are at /usr/local/www/data/datastore-specifications/scripts/
# If not added already to the PATH, do:
    PATH=/usr/local/www/data/datastore-specifications/scripts:$PATH 

# Variables for this job
  PRIVATE=/usr/local/www/data/private   # Set this to the Data Store private root directory, i.e. ...data/private/
  PZGSP=Pcoccineus  # For Phytozome, use the (G)(species) name, e.g. Gmax
  PZVER=v1.1  # For Phytozome, use the directory name that indicates the version, e.g. v1.1 or V3.1
  STRAIN=PHA8298
  GENUS=Phaseolus
  SP=coccineus
  GENSP=phaco
  GNM=gnm1
  ANN=ann1  
  GENOME=Pcoccineus_703_v1.0
  ANNOTATION=Pcoccineus_703_v1.1
  CONFIGDIR=/usr/local/www/data/datastore-specifications/scripts/ds_souschef_configs

# Register new keys at peanutbase-stage:/usr/local/www/data/datastore-registry
# NOTE: Remember to fetch and pull before generating new keys.
  cd /usr/local/www/data/datastore-registry
  ./register_key.pl -v "$GENUS $SP genomes $STRAIN.$GNM"
  ./register_key.pl -v "$GENUS $SP annotations $STRAIN.$GNM.$ANN"
# NOTE: Remember to add, commit, and push the updated ds_registry.tsv  
  GKEY=PYJ1
  AKEY=0Q14

# Make and cd into a work directory
  mkdir -p $PRIVATE/$GENUS/$SP
  cd $PRIVATE/$GENUS/$SP
  mkdir $STRAIN.$GNM.$ANN
  cd $STRAIN.$GNM.$ANN

# Move the version directory out of the containing Phytozome/PhytozomeV## directory
  cd $PRIVATE/$GENUS/$SPECIES
  mv Phytozome/PhytozomeV13/$PZGSP/* .
  rm -rf Phytozome

#####
# Download the assembly and annotation files.
# Assembly was downloaded on 2023-10-23
# https://phytozome-next.jgi.doe.gov/info/Pcoccineus_v1_1

# Copy the Phytozome readme file into the annotation and assembly directories so ds_souschef can find it in those locations:
  cp $PZVER/*DataReleasePolicy.html $PZVER/*readme.txt $PZVER/annotation/
  cp $PZVER/*DataReleasePolicy.html $PZVER/*readme.txt $PZVER/assembly/

# Change in the Phytozome annotation version, for consistency with assembly vs. annotation prefixes.
# For example, if Phytozome annotations are v1.1, the annotations are v1.0
  rename.pl 's/_v1.1/_v1.0/' $PZVER/assembly/*html
  rename.pl 's/_v1.1/_v1.0/' $PZVER/assembly/*txt

# Check the files. If the assembly sequence is not wrappeed (to permit indexing), fix this.
# Also check the form of the chromosome and scaffold names. 

# Derive bed file
  zcat $PZVER/annotation/$ANNOTATION.gene.gff3.gz | 
    gff_to_bed7_mRNA.awk | sort -k1,1 -k2n,2n | gzip --stdout > $PZVER/annotation/$ANNOTATION.gene.bed.gz

# Compress annotation_info and defline  text files in annotations
  gzip $PZVER/annotation/*annotation_info.txt
  gzip $PZVER/annotation/*defline.txt

# cd back to the main work directory
  cd $PRIVATE/$GENUS/$SP/$STRAIN.$GNM.$ANN

# Prepare the config for ds_souschef 
  vim $CONFIGDIR/$GENSP.$STRAIN.$GNM.$ANN.yml

# Run ds_souschef.pl with the config above
  ds_souschef.pl -config $CONFIGDIR/$GENSP.$STRAIN.$GNM.$ANN.yml

# In the working directory, validate the READMEs and correct (upstream, in the ds_souschef yml) if necessary
  validate.sh readme annotations/$STRAIN.$GNM.$ANN.$AKEY/README*
  validate.sh readme genomes/$STRAIN.$GNM.$GKEY/README*

# Compress and index
  compress_and_index.sh annotations/$STRAIN.$GNM.$ANN.$AKEY
  compress_and_index.sh genomes/$STRAIN.$GNM.$GKEY

# Calculate md5sum
  mdsum-folder.bash annotations/$STRAIN.$GNM.$ANN.$AKEY
  mdsum-folder.bash genomes/$STRAIN.$GNM.$GKEY

# Move to annex, for next steps by Andrew (AHRD and BUSCO)
  mkdir -p /usr/local/www/data/annex/$GENUS/$SP/annotations/
  mkdir -p /usr/local/www/data/annex/$GENUS/$SP/genomes/

  mv annotations/$STRAIN.$GNM.$ANN.$AKEY /usr/local/www/data/annex/$GENUS/$SP/annotations/
  mv genomes/$STRAIN.$GNM.$GKEY /usr/local/www/data/annex/$GENUS/$SP/genomes/

# Push the ds_souschef config to GitHub

