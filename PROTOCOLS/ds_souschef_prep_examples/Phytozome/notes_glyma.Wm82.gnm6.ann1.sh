# Objective: Prepare assembly and annotation collection for Glycine max accession Wm82
# Started on 2024-02-20

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

# NOTE: utility scripts are at /usr/local/www/data/datastore-specifications/scripts/
# If not added already to the PATH, do:
    PATH=/usr/local/www/data/datastore-specifications/scripts:$PATH 

# Variables for this job
  PRIVATE=/usr/local/www/data/private   # Set this to the Data Store private root directory, i.e. ...data/private/
  PZGSP=Gmax # For Phytozome, use the (G)(species) name, e.g. Gmax
  export PZVER="Wm82.a6.v1"  # For Phytozome, use the directory name that indicates the version, e.g. v1.1 or V3.1
  STRAIN=Wm82
  GENUS=Glycine
  SP=max
  GENSP=glyma
  GNM=gnm6
  ANN=ann1  
  GENOME=Gmax_880_v6.0
  ANNOTATION=Gmax_880_Wm82.a6.v1
  CONFIGDIR=/usr/local/www/data/datastore-specifications/scripts/ds_souschef_configs

# NOTE: Get the keys with register_key.pl below !
  GKEY=S97D
  AKEY=PKSW

# Register new keys at peanutbase-stage:/usr/local/www/data/datastore-registry
# NOTE: Remember to fetch and pull before generating new keys.
  cd /usr/local/www/data/datastore-registry
  ./register_key.pl -v "$GENUS $SP genomes $STRAIN.$GNM"
  ./register_key.pl -v "$GENUS $SP annotations $STRAIN.$GNM.$ANN"
# NOTE: Remember to add, commit, and push the updated ds_registry.tsv  

# Make and cd into a work directory
  mkdir -p $PRIVATE/$GENUS/$SP/$STRAIN.$GNM.$ANN
  cd $PRIVATE/$GENUS/$SP/$STRAIN.$GNM.$ANN

# Download the assembly and annotation files.
# Move the version directory out of the containing Phytozome/PhytozomeV## directory
  mv Phytozome/PhytozomeV13/$PZGSP/* .
  rm -rf Phytozome

# Copy the Phytozome readme file into the annotation and assembly directories so ds_souschef can find it in those locations:
  cp $PZVER/*DataReleasePolicy.html $PZVER/*readme.txt $PZVER/annotation/
  cp $PZVER/*DataReleasePolicy.html $PZVER/*readme.txt $PZVER/assembly/

# Check the files. If the assembly sequence is not wrappeed (to permit indexing), fix this.
# Also check the form of the chromosome and scaffold names. 

#####
# A challenge with Phytozome files is that they have a version suffix in the gene.gff3 file, 
# e.g. `.v1.1` in `Phcoc.01G000300.v1.1`
# Currently (early 2024), these are best handled by stripping the version suffix from IDs in the gff3 file,
# but the fasta files do not, e.g. `Phcoc.01G000300`
# Fix this inconsistency by removing the version string from the gff3.
  
  zcat $PZVER/annotation/$ANNOTATION.gene.gff3.gz | 
    perl -pe 'BEGIN{$VER=$ENV{"PZVER"}; $REX=qr/\.$VER/}; s/$REX//g' |
    gzip -c > $PZVER/annotation/$ANNOTATION.gene_strip.gff3.gz

  zcat $PZVER/annotation/$ANNOTATION.gene_exons.gff3.gz | 
    perl -pe 'BEGIN{$VER=$ENV{"PZVER"}; $REX=qr/\.$VER/}; s/$REX//g' |
    gzip -c > $PZVER/annotation/$ANNOTATION.gene_exons_strip.gff3.gz

# Compress annotation_info and defline  text files in annotations
  gzip $PZVER/annotation/*annotation_info.txt
  gzip $PZVER/annotation/*defline.txt

  gzip $PZVER/annotation/$ANNOTATION.locus_transcript_name_map.txt

# Prepare the config for ds_souschef. Typically, copy from a similar config file and revise.
  vim $CONFIGDIR/$GENSP.$STRAIN.$GNM.$ANN.yml

# Run ds_souschef.pl with the config above
  ds_souschef.pl -config $CONFIGDIR/$GENSP.$STRAIN.$GNM.$ANN.yml

# NOTE: Check the results for sanity. 
# The fasta files (cds, transcript, protein) should all have prefixes (gensp.genotype.gnm#.ann#.)
# If there are any cases of "HASH UNDEFINED", then check whether the gff "strip" step produced
# the desired result. If not (if the Phytozome version suffix is still present), check that 
# $PZVER is correct and was exported.  

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
  mkdir -p /usr/local/www/data/annex/$GENUS/$SP/annotations/
  mkdir -p /usr/local/www/data/annex/$GENUS/$SP/genomes/

  mv annotations/$STRAIN.$GNM.$ANN.$AKEY /usr/local/www/data/annex/$GENUS/$SP/annotations/
  mv genomes/$STRAIN.$GNM.$GKEY /usr/local/www/data/annex/$GENUS/$SP/genomes/

# Push the ds_souschef config to GitHub
  cd $CONFIGDIR
  git status  # etc.

