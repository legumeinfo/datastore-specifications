# Objective: Prepare assembly and annotation collection for Pisum sativum
# accession Cameor
# Started on 2026-05-22 (Steven Cannon, Wei Huang)

# See the document here for detailed (general) instructions:
#   https://github.com/legumeinfo/datastore-specifications/tree/main/PROTOCOLS/README.md

cat << DONT_RUN_ME
This file contains notes for creating genome and annotation collections for the Data Store. Read them critically,
revise for your particular job, and copy-paste in an interactive terminal session. The file has a suffix ".sh"
only to get syntax highlighting in an editor (e.g. vim). It should not be executied as a shell script.
DONT_RUN_ME
echo; exit 1;

<< REFERENCE
Kreplak J, Novák P, Ávila Robledillo L, Aubert G, Imbert B, Kaur P, Gouil Q, Lopez-Roques C, Rodde N, Bouchez O, Tayeh N, Macas J, Burstin J. A new genome assembly of the pea cultivar 'Caméor' provides resources for functional genomics and genetics. Sci Data. 2026 May 12. doi: 10.1038/s41597-026-07347-4. Epub ahead of print. PMID: 42120873.
REFERENCE

# Assembly was downloaded on 2024-04-08 from Recherche Data Gouv:
# https://doi.org/10.57745/5MDE99
#  and
# https://www.ebi.ac.uk/ena/browser/view/GCA_977071245

# NOTE: utility scripts are at /project/legume_project/datastore/datastore-specifications/scripts/
# If not added already to the PATH, do:
    PATH=/project/legume_project/datastore/datastore-specifications/scripts:$PATH

# Variables for this job
  PRIVATE=/project/legume_project/datastore/private/   # Set this to the Data Store private root directory: ...data/private/
  ACCN=GCA_977071245
  STRAIN=Cameor
  GENUS=Pisum
  SP=sativum
  GENSP=pissa
  GNM=gnm2
  ANN=ann1  
  GENOME=cameor_v2 # The filename prefix common among all genome files in the source
  ANNOTATION=CAMEOR_V2_ANNOTATION_1 # The filename prefix ommon among all annotation files in the source
  CONFIGDIR=/project/legume_project/datastore/datastore-specifications/scripts/ds_souschef_configs

# NOTE: Get the keys with register_key.pl below !
  GKEY=H2BH
  AKEY=KT6X

# Register new keys at /project/legume_project/datastore/datastore-registry
# NOTE: Remember to fetch and pull before generating new keys.
  cd /project/legume_project/datastore/datastore-registry
  ./register_key.pl -v "$GENUS $SP genomes $STRAIN.$GNM"
  ./register_key.pl -v "$GENUS $SP annotations $STRAIN.$GNM.$ANN"
# NOTE: Remember to add, commit, and push the updated ds_registry.tsv  

# Make and cd into a work directory
  mkdir -p $PRIVATE/$GENUS/$SP/$STRAIN.$GNM.$ANN
  cd $PRIVATE/$GENUS/$SP/$STRAIN.$GNM.$ANN

# Download the assembly and annotation files (using curl)

# Check the files. If the assembly sequence is not wrappeed (to permit indexing), fix this.
# Also check the form of the chromosome and scaffold names. 

# These files look pretty standard; no need to keep separate sets in original/ and derived/

  salloc
  ml miniconda
  source activate ds-curate

# Extract transcript sequence
  cd original
    gunzip cameor_v2.fa.gz
    gffread -g cameor_v2.fa \
      -w CAMEOR_V2_ANNOTATION_1_transcripts.fasta \
         CAMEOR_V2_ANNOTATION_1.gff3

# Derive primary/longest CDS, transcript, and protein sequences
# ... but there is only one variant per gene, so skip this step.

# The gene IDs have this structure:
#   Psat.cameor.v2.1g00050.1
#   Psat.cameor.v2.1g00100.1
#   ...
#   Psat.cameor.v2.0s0921g00050.1
#   Psat.cameor.v2.0s0958g00050.1

# Change to this prefix pattern:
#   pissa.Cameor.gnm2.ann1.Psat.1g00050.1
#   pissa.Cameor.gnm2.ann1.Psat.1g00100.1
#   ...
#   pissa.Cameor.gnm2.ann1.Psat.0s0921g00050.1
#   pissa.Cameor.gnm2.ann1.Psat.0s0958g00050.1



# Since we will be adding our own prefixes, we will remove the current prefixes.

  cd $PRIVATE/$GENUS/$SP/$STRAIN.$GNM.$ANN

  mkdir derived

  cat original/CAMEOR_V2_ANNOTATION_1_cds.fasta |
   perl -pe 's/Psat.cameor.v2./Psat./' > derived/CAMEOR_V2_ANNOTATION_1.cds.fna
  cat original/CAMEOR_V2_ANNOTATION_1_transcripts.fasta | 
    perl -pe 's/Psat.cameor.v2./Psat./' > derived/CAMEOR_V2_ANNOTATION_1.transcripts.fna
  cat original/CAMEOR_V2_ANNOTATION_1_prot.fasta | 
    perl -pe 's/Psat.cameor.v2./Psat./' > derived/CAMEOR_V2_ANNOTATION_1.proteins.faa
  cat original/CAMEOR_V2_ANNOTATION_1.gff3 |
    perl -pe 's/Psat.cameor.v2./Psat./g' >derived/CAMEOR_V2_ANNOTATION_1.gff3
# Compress the files
  for file in original/*fasta original/*fa original/*gff3 derived/*; do
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

  # NOTE: the chromosomes are too big for standard tabix, so do:
  tabix --csi annotations/Cameor.gnm2.ann1.KT6X/pissa.Cameor.gnm2.ann1.KT6X.gene_models_main.gff3.gz


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

