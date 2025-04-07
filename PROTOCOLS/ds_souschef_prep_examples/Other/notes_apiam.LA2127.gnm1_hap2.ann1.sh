# Objective: Prepare assembly collection for Apios americana accession LA2127
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
Belamkar, V., Farmer, A.D., Weeks, N.T. Kalberer S.R., Blackmon, W.J., Cannon, S.B. Genomics-assisted characterization of a breeding collection of Apios americana, an edible tuberous legume. Sci Rep 6, 34908 (2016). https://doi.org/10.1038/srep34908
REFERENCE

# NOTE: utility scripts are at 
# If not added already to the PATH, do:
    PATH=/project/legume_project/datastore/datastore-specifications/scripts:$PATH 

# Variables for this job
  PRIVATE=/project/legume_project/datastore/private   # Set this to the Data Store private root directory, i.e. ...data/private/
  STRAIN=LA2127
  GENUS=Apios
  SP=americana
  GENSP=apiam
  GNM=gnm1_hap2
  ANN=ann1  
  GENOME=Apios.americana # The filename prefix common among all genome files in the source
  ANNOTATION=Apios.americana # The filename prefix ommon among all annotation files in the source
  CONFIGDIR=/project/legume_project/datastore/datastore-specifications/scripts/ds_souschef_configs


# NOTE: Get the keys with register_key.pl below !
  GKEY=3WWC
  AKEY=NT2R

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

 zcat original/Apios.americana.hap2.fa.gz | perl -pe 's/apios.americana.hap2.chr/Chr/' > derived/Apios.americana.hap2.fna


# Check the files. If the assembly sequence is not wrappeed (to permit indexing), fix this.
# Also check the form of the chromosome and scaffold names. 

# For consistency in config file, add suffixes to braker sequence files
  mv derived/braker.aa derived/braker.aa.faa
  mv derived/braker.codingseq derived/braker.codingseq.fna

# Remove datastore prefixes from annotation files, to match the "bare" original assembly
  perl -pi -e 's/^api\w\w\.\w+\.\w+\.//' derived/braker.g*

# Extract transcript sequence
  gffread -g derived/Apios.americana.hap2.fna -w derived/braker.transcripts.fna derived/braker.gff3

# Derive primary/longest CDS, transcript, and protein sequences
  cat derived/braker.transcripts.fna | longest_variant_from_fasta.sh > derived/braker.transcripts_primary.fna &
  cat derived/braker.codingseq.fna | longest_variant_from_fasta.sh > derived/braker.CDS_primary.fna &
  cat derived/braker.aa.faa | longest_variant_from_fasta.sh > derived/braker.protein_primary.faa &
  wait


# Compress the files
  for file in derived/*.f?a derived/*.gff3; do 
    bgzip -l9 $file &
  done

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

