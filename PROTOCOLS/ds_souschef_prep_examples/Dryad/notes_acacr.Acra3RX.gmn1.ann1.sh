# Objective: Prepare assembly and annotation collection for Acacia crassicarpa
# accession Acra3RX (Acra3. Pool of RNA from 40-80 individuals from seed accession 19724 from the Australian Tree Seed Center.)
# Started on 2024-02-12(Steven Cannon)

# See the document here for detailed (general) instructions:
#   https://github.com/legumeinfo/datastore-specifications/tree/main/PROTOCOLS/README.md

cat << DONT_RUN_ME
This file contains notes for creating genome and annotation collections for the Data Store. Read them critically,
revise for your particular job, and copy-paste in an interactive terminal session. The file has a suffix ".sh"
only to get syntax highlighting in an editor (e.g. vim). It should not be executied as a shell script.
DONT_RUN_ME
echo; exit 1;

<< REFERENCE
Massaro I, Poethig RS, Sinha NR, Leichty AR. Genome Report: Chromosome-level genome of the transformable northern wattle, Acacia crassicarpa. G3 (Bethesda). 2023 Dec 14:jkad284. doi: 10.1093/g3journal/jkad284. Epub ahead of print. PMID: 38096217.
REFERENCE

# Assembly was downloaded on 2024-02-12 from Data Dryad
# https://datadryad.org/stash/dataset/doi:10.5061/dryad.573n5tbdr

# NOTE: utility scripts are at /usr/local/www/data/datastore-specifications/scripts/
# If not added already to the PATH, do:
    PATH=/usr/local/www/data/datastore-specifications/scripts:$PATH 

# Variables for this job
  PRIVATE=/usr/local/www/data/private/   # Set this to the Data Store private root directory, i.e. ...data/private/
  ACCN=dryad_573n5tbdr  # Derived from the Dryad dataset DOI - in this case, https://doi.org/10.5061/dryad.573n5tbdr
  STRAIN=Acra3RX
  GENUS=Acacia
  SP=crassicarpa
  GENSP=acacr
  GNM=gnm1
  ANN=ann1  
  CONFIGDIR=/usr/local/www/data/datastore-specifications/scripts/ds_souschef_configs
  ANNOT_PREFIX=Acra_USDA_v1
  GENOME=$ANNOT_PREFIX.fsa
  FROM=$ACCN
  TO=derived

# NOTE: Get the keys with register_key.pl below !
  GKEY=YX4L
  AKEY=6C0V

# Register new keys at peanutbase-stage:/usr/local/www/data/datastore-registry
# NOTE: Remember to fetch and pull before generating new keys.
  cd /usr/local/www/data/datastore-registry
  ./register_key.pl -v "$GENUS $SP genomes $STRAIN.$GNM"
  ./register_key.pl -v "$GENUS $SP annotations $STRAIN.$GNM.$ANN"
# NOTE: Remember to add, commit, and push the updated ds_registry.tsv  

# Make and cd into a work directory
  mkdir -p $PRIVATE/$GENUS/$SP/$STRAIN.$GNM.$ANN
  cd $PRIVATE/$GENUS/$SP/$STRAIN.$GNM.$ANN

# Put the original files in original/ and manually derived files in derived/
  mkdir -p $FROM $TO

# For Dryad files, put them into the $ACCN directory (representing the Dryad data collection)
  mkdir $ACCN
  mv $ANNOT_PREFIX* $ACCN

# Check the files.
# The assembly has the sequence wrapped lines with a width of 60 to permit subsequent indexing.

#### Problems: 
# (1) Some lines in the GTF had spaces as separators rather than tabs. I fixed this manually (in vim)
  cat $FROM/$ANNOT_PREFIX.gtf | 
    perl -pe 's/^(\S+) +(\S+) +(\S+) +(\S+) +(\S+) +(\S+) +(\S+) +(\S+) +(\S+)/$1\t$2\t$3\t$4\t$5\t$6\t$7\t$8\t$9/' |
    cat > $FROM/$ANNOT_PREFIX.mod1.gtf

# (2) Will need to generate GFF from GTF (since our other tools operate on GFF)
# To do the GTF-->GFF conversion, I copied the GTF to ceres, then used conda to install agat
## NOTE: Next several steps were run on ceres
##  ml miniconda
##  conda install -c bioconda agat
##  conda install -n agat -c conda-forge -c bioconda agat
##
##  source activate agat
##  agat_convert_sp_gxf2gxf.pl --gtf $ANNOT_PREFIX.mod1.gtf -o $ANNOT_PREFIX.genes_exons.gff3

# Back on peanutbase-stage:
# Also make a version without exons (seems necessary for extracting transcript sequences with gffread)
  cat $TO/$ANNOT_PREFIX.genes_exons.gff3 | awk '$3!~/exon/' > $TO/$ANNOT_PREFIX.genes.gff3

# Copy primary assembly to the $TO directory, renaming it to something more recognizable
  cp $FROM/$ANNOT_PREFIX.fsa $TO/$ANNOT_PREFIX.genome.fasta

# Extract CDS, mRNA, and protein sequence. Note that this uses genes.gff3 rather than genes_exons.gff3
  gffread -g $FROM/$ANNOT_PREFIX.genome.fasta \
          -w $TO/$ANNOT_PREFIX.transcripts.fna -x $TO/$ANNOT_PREFIX.CDS.fna -y $TO/$ANNOT_PREFIX.protein.faa \
             $TO/$ANNOT_PREFIX.genes.gff3

# Derive primary/longest CDS, transcript, and protein sequences
  cat $TO/$ANNOT_PREFIX.transcripts.fna | longest_variant_from_fasta.sh > $TO/$ANNOT_PREFIX.transcripts_primary.fna &
  cat $TO/$ANNOT_PREFIX.CDS.fna | longest_variant_from_fasta.sh > $TO/$ANNOT_PREFIX.CDS_primary.fna &
  cat $TO/$ANNOT_PREFIX.protein.faa | longest_variant_from_fasta.sh > $TO/$ANNOT_PREFIX.protein_primary.faa &
  wait


# Compress the files
  for file in $TO/*gff3 $TO/*f?a $TO/*bed $TO/*.fasta; do 
    bgzip $file &
  done 

  rm $TO/*fai

#####
# Prepare the config for ds_souschef, 
# at /usr/local/www/data/datastore-specifications/scripts/ds_souschef_configs 
# cd back to the main work directory
  cd $PRIVATE/$GENUS/$SP/$STRAIN.$GNM.$ANN
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

