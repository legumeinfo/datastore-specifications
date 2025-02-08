# Objective: Prepare assembly and annotation collection for Phytozome Chamaecrista fasciculata
# Started on 2024-06-26

# See the document here for detailed (general) instructions:
#   https://github.com/legumeinfo/datastore-specifications/tree/main/PROTOCOLS/README.md

cat << DONT_RUN_ME
This file contains notes for creating genome and annotation collections for the Data Store. Read them critically, 
revise for your particular job, and copy-paste in an interactive terminal session. The file has a suffix ".sh" 
only to get syntax highlighting in an editor (e.g. vim). It should not be executied as a shell script.
DONT_RUN_ME
echo; exit 1;

<< REFERENCE
Lee H, Stai JS, ... Leebens-Mack, Cannon SB. New reference genome assemblies for Cercis canadensis and Chamaecrista fasciculata clarify evolutionary histories of legume nodulation and genome structure (in preparation)
REFERENCE

# NOTE: utility scripts are at /project/legume_project/datastore/datastore-specifications/scripts/
# If not added already to the PATH, do:
    PATH=/project/legume_project/datastore/datastore-specifications/scripts:$PATH 

# NOTE: Resolved haplotypes in this data set are a challenge for curation. At Phytozome, these data are handled as two collections named
# with directory and filename prefixes like the following:
#   Cfasciculatavar_ISC494698HAP1
#   Cfasciculatavar_ISC494698HAP2
# Data preparation strategy: For the final collections at the Data Store, produce two sets of collections (genomes and annotations)
# For haplotype 2, label these with gnm1_hap2 -- since the haplotypes are distinguished by the distinct genome assemblies.
# For haplotype 1, just use gnm1 (sans _hap1), and treat this as the primary one for most analyses.
# Prepare these using two ds_souschef config files.

# Variables for this job
  PRIVATE=/project/legume_project/datastore/private   # Set this to the Data Store private root directory, i.e. ...data/private/
  PZGSP=Cfasciculatavar_ISC494698HAP2 # For Phytozome, use the directory name that contains the versioned directory.
  export PZVER="v1.1"  # For Phytozome, use the directory name that indicates the version, e.g. v1.1 or V3.1
  STRAIN=ISC494698
  GENUS=Chamaecrista
  SP=fasciculata
  GENSP=chafa
  GNM=gnm1_hap2
  ANN=ann1
  GENOME=Cfasciculatavar_ISC494698HAP2_855_v1.0
  ANNOTATION=Cfasciculatavar_ISC494698HAP2_855_v1.1
  CONFIGDIR=/project/legume_project/datastore/datastore-specifications/scripts/ds_souschef_configs

# NOTE: Get the keys with register_key.pl below !
  GKEY=G6BY
  AKEY=WXZF

## Register new keys at peanutbase-stage:/project/legume_project/datastore/datastore-registry
## NOTE: Remember to fetch and pull before generating new keys.
#  cd /project/legume_project/datastore/datastore-registry
#  ./register_key.pl -v "$GENUS $SP genomes $STRAIN.$GNM"
#  ./register_key.pl -v "$GENUS $SP annotations $STRAIN.$GNM.$ANN"
## NOTE: Remember to add, commit, and push the updated ds_registry.tsv  

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
# e.g. `.v1.1` in `ChfasH1.1G000400.v1.1`
# but the fasta files do not, e.g. `ChfasH1.1G000400.1.p`
# Currently (early 2024), these are best handled by stripping the version suffix from IDs in the gff3 file,
# Fix this inconsistency by removing the version string from the gff3.
  
  zcat $PZVER/annotation/$ANNOTATION.gene.gff3.gz | 
    perl -pe 'BEGIN{$VER=$ENV{"PZVER"}; $REX=qr/\.$VER/}; s/$REX//g' |
    gzip -c > $PZVER/annotation/$ANNOTATION.gene_strip.gff3.gz

  zcat $PZVER/annotation/$ANNOTATION.gene_exons.gff3.gz | 
    perl -pe 'BEGIN{$VER=$ENV{"PZVER"}; $REX=qr/\.$VER/}; s/$REX//g' |
    gzip -c > $PZVER/annotation/$ANNOTATION.gene_exons_strip.gff3.gz

# Prepare the config for ds_souschef. Typically, copy from a similar config file and revise.
  vim $CONFIGDIR/$GENSP.$STRAIN.$GNM.$ANN.yml

# Run ds_souschef.pl with the config above. This can be run from anywhere, since the work_directory is set in the config;
# but for consistency, the work directory should generally be $PRIVATE/$GENUS/$SP/$STRAIN.$GNM.$ANN
  cd $PRIVATE/$GENUS/$SP/$STRAIN.$GNM.$ANN
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

