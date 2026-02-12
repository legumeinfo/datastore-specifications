# Objective: Prepare assembly and annotation collection for Glycine max accession Wm82, initial (2010) annotation.
# This was a problematic early annotation, called V8 at Phytosome, collection "Glycine max JGI Glyma1". 
# It was replaced in ~2012 by V9, collection "Glycine max v1.1", with the same genome coordinates.
# Started on 2026-02-09

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

# NOTE: utility scripts are at /project/legume_project/datastore/datastore-specifications/scripts/
# If not added already to the PATH, do:
    PATH=/project/legume_project/datastore/datastore-specifications/scripts:$PATH 

# Variables for this job
  PRIVATE=/project/legume_project/datastore/private   # Set this to the Data Store private root directory, i.e. ...data/private/
  PZGSP=Gmax # For Phytozome, use the (G)(species) name, e.g. Gmax
  export PZVER="PhytozomeV8_Gmax_109" # NOTE: This is nonstandard, due to the nonstandard Phytozome collection
  STRAIN=Wm82
  GENUS=Glycine
  SP=max
  GENSP=glyma
  GNM=gnm1
  ANN=ann0  
  GENOME=Gmax_109.fa.gz
  ANNOTATION=Glyma1
  CONFIGDIR=/project/legume_project/datastore/datastore-specifications/scripts/ds_souschef_configs

# NOTE: Get the keys with register_key.pl below !
  GKEY=FCtY
  AKEY=3BTZ

# Register new keys at peanutbase-stage:/project/legume_project/datastore/datastore-registry
# NOTE: Remember to fetch and pull before generating new keys.
  cd /project/legume_project/datastore/datastore-registry
  ./register_key.pl -v "$GENUS $SP genomes $STRAIN.$GNM"
  ./register_key.pl -v "$GENUS $SP annotations $STRAIN.$GNM.$ANN"
# NOTE: Remember to add, commit, and push the updated ds_registry.tsv  

# Make and cd into a work directory.
# NOTE: Because this first assembly version is nonstandard, the following steps are as well.
  mkdir -p $PRIVATE/$GENUS/$SP/Wm82_v1_instances/PhytozomeV8_derived
  cd $PRIVATE/$GENUS/$SP/Wm82_v1_instances/PhytozomeV8_derived

# Download the assembly and annotation files.
# Move the version directory out of the containing Phytozome/PhytozomeV## directory
  # The collection name at Phytozome was "Glycine max JGI Glyma1". The name locally is PhytozomeV8_Gmax_109

# Copy the Phytozome readme file into the annotation and assembly directories so ds_souschef can find it in those locations:
  cp ../$PZVER/Gmax_109_readme.txt .

# Check the files. If the assembly sequence is not wrappeed (to permit indexing), fix this.
# Also check the form of the chromosome and scaffold names. 

# Extract mRNA sequence
  gffread -g Gmax_109.fna \
    -w from_gffread/Glyma1.derived.transcript.fna \
    -x from_gffread/Glyma1.derived.cds.fna \
    -y from_gffread/Glyma1.derived.protein.faa Glyma1.gff3
# PROBLEM: many of the derived protein sequences have internal stops:
  zcat Glyma1.derived.protein_primary.faa.gz | fasta_to_table.awk | awk -v OFS="\t" '$2~/[A-Z]+\.[A-Z]+/ {print $1}' | wc -l
    8120  # Not good
# Instead, use the sequences from the original annotation:
  cp ../PhytozomeV8_Gmax_109/Glyma1.cDNA.fa.gz .
  cp ../PhytozomeV8_Gmax_109/Glyma1.pep.fa.gz .
  cp ../PhytozomeV8_Gmax_109/Glyma1.unprocessedTranscript.fa.gz .

# Check for internal stops:
  zcat Glyma1.pep.fa.gz | fasta_to_table.awk | awk -v OFS="\t" '$2~/[A-Z]+\*[A-Z]+/ {print $1}' | wc -l
    176  # OK

# Derive bed file
  cat Glyma1.gff3 | gff_to_bed7_mRNA.awk | sort -k1,1 -k2n,2n > Glyma1.bed

# Derive primary CDS/proteins/transcripts
  zcat Glyma1.cDNA.fa.gz | longest_variant_from_fasta.sh > Glyma1.cDNA_primary.fna
  zcat Glyma1.pep.fa.gz  | longest_variant_from_fasta.sh > Glyma1.pep_primary.faa
  zcat Glyma1.unprocessedTranscript.fa.gz | longest_variant_from_fasta.sh > Glyma1.transcript_primary.fna

# Compress the data files
  for file in Glyma1.derived*f?a Glyma1.derived*bed Glyma1.gff3 Gmax_109.fa; do 
    echo $file
    bgzip $file &
  done

# Return to the main working directory
  cd $PRIVATE/$GENUS/$SP/Wm82_v1_instances/

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

