# Objective: prepare assembly for Data Store. File-prep started 2026-07-02
# run on ceres.scinet.usda.gov
# W.Huang

# See the document here for detailed (general) instructions:
#   https://github.com/legumeinfo/datastore-specifications/tree/main/PROTOCOLS

# Data from https://data.4tu.nl/datasets/1ba67d64-ddee-4925-8faa-f084c78a3419


cat << DONT_RUN_ME
This file contains notes for creating genome and annotation collections for the Data Store. Read them critically,
revise for your particular job, and copy-paste in an interactive terminal session. The file has a suffix ".sh"
only to get syntax highlighting in an editor (e.g. vim). It should not be executied as a shell script.
DONT_RUN_ME
echo; exit 1;

<< REFERENCE
Pancaldi F, Gulisano A, Severing EI, van Kaauwen M, Finkers R, Kodde L, Trindade LM. The genome of Lupinus mutabilis: Evolution and genetics of an emerging bio-based crop. Plant J. 2024 Nov;120(3):881-900. doi: 10.1111/tpj.17021. Epub 2024 Sep 12. PMID: 39264984.
REFERENCE

# NOTE: utility scripts are at /project/legume_project/datastore/datastore-specifications/scripts/
# If not added already to the PATH, do:
    PATH=/project/legume_project/datastore/datastore-specifications/scripts:$PATH 

# Variables for this job
  PRIVATE=/project/legume_project/datastore/private  # Set this to the Data Store private root directory, i.e. ...data/private
  STRAIN=Inti
  GENUS=Lupinus
  SP=mutabilis
  GENSP=lupmu
  GNM=gnm1
  ANN=ann1  
  GENOME=PO2632_Lupinus_mutabilis.UnMasked.fasta
  CONFIGDIR=/project/legume_project/datastore/datastore-specifications/scripts/ds_souschef_configs
  FROM=original
  TO=derived
# NOTE: Get the keys with register_key.pl below !
  GKEY=4L6N
  AKEY=0FRM

# Register new keys at peanutbase-stage:/project/legume_project/datastore/datastore-registry
# NOTE: Remember to fetch and pull before generating new keys.
  cd /project/legume_project/datastore/datastore-registry
  ./register_key.pl -v "$GENUS $SP genomes $STRAIN.$GNM"
  ./register_key.pl -v "$GENUS $SP annotations $STRAIN.$GNM.$ANN"
# NOTE: Remember to add, commit, and push the updated ds_registry.tsv  

# Make and cd into a work directory
  mkdir -p $PRIVATE/$GENUS/$SP/$STRAIN.$GNM.$ANN
  cd $PRIVATE/$GENUS/$SP/$STRAIN.$GNM.$ANN

# Get the genome assembly and annotations
#  download data from 
curl -O "https://data.4tu.nl/ndownloader/items/1ba67d64-ddee-4925-8faa-f084c78a3419/versions/1"
# Uncompress and move files into an easily accessible "from" directory
  unzip 1
  
 mv * $FROM
# Prepare the data here:
  cd $PRIVATE/$GENUS/$SP/$STRAIN.$GNM.$ANN


# Check the files.
# All other sequences are wrapped at 50 bases.
module load miniconda 
source activate /project/legume_project/datastore/conda-envs/ds-curate
    
# Remove "Genome" from the first line of the assembly file, change from CRLF to LF line endings, and rewrap to with of 80 char
  cat original/PO2632_Lupinus_mutabilis.UnMasked.fasta | tr -d '\r' | grep -v Genome |
    fasta_to_one_line.awk | fold -w 80 > derived/PO2632_Lupinus_mutabilis.Unmasked.mod.fasta

# Replace "-RA" in transcript IDs with ".1"
  cat original/PO2632_Lupinus_mutabilis.annotation.gff | sort_gff.pl | 
    perl -pe 's/-RA/.1/g' > derived/PO2632_Lupinus_mutabilis.annot.mod.gff

# Use gffread to derive protein, CDS, and transcript files; then separate GFF into coding and noncoding
# based on list of protein-coding genes.

  cd derived

  gffread -g PO2632_Lupinus_mutabilis.Unmasked.mod.fasta \
          -w PO2632_Lupinus_mutabilis.transcript.fna \
          -x PO2632_Lupinus_mutabilis.CDS.fna \
          -y PO2632_Lupinus_mutabilis.protein.faa \
             PO2632_Lupinus_mutabilis.annot.mod.gff

  grep '>' PO2632_Lupinus_mutabilis.protein.faa | sed 's/>//' > lis.coding

  cat PO2632_Lupinus_mutabilis.annot.mod.gff | split_gff_by_mRNA_list.pl -list lis.coding \
       -match PO2632_Lupinus_mutabilis.annot.coding.gff \
       -non PO2632_Lupinus_mutabilis.annot.noncoding.gff

# Derive bed file
  cat PO2632_Lupinus_mutabilis.annot.coding.gff | gff_to_bed7_mRNA.awk | sort -k1,1 -k2n,2n > PO2632_Lupinus_mutabilis.annot.coding.bed

# Compress the files
  cd derived

  for file in *gff *f?a *bed *.fasta; do 
    bgzip -l9 $file &
  done 
  wait

  rm *fai

# Split gff into coding and noncoding genes

# cd back to the main work directory
  cd $PRIVATE/$GENUS/$SP/$STRAIN.$GNM.$ANN

# Prepare the config for ds_souschef, in the datastore-specifications/scripts/ds_souschef_configs directory
  vim $CONFIGDIR/$GENSP.$STRAIN.$GNM.$ANN.yml

# Run ds_souschef.pl with the config above
  ds_souschef.pl -config $CONFIGDIR/$GENSP.$STRAIN.$GNM.$ANN.yml

# NOTE: Check the results for sanity.
# The fasta files (cds, transcript, protein) should all have prefixes (gensp.genotype.gnm#.ann#.)
  cd $PRIVATE/$GENUS/$SP/$STRAIN.$GNM.$ANN

  echo "Testing for hashing correctness. Counts of UNDEFINED should be 0 in all files."
  grep -c UNDEFINED annotations/$STRAIN.$GNM.$ANN.$AKEY/*

# In the working directory, validate the READMEs and correct (upstream, in the ds_souschef yml) if necessary

  validate.sh readme annotations/$STRAIN.$GNM.$ANN.$AKEY/README*
  validate.sh readme genomes/$STRAIN.$GNM.$GKEY/README*

# Also check MANIFESTs
  yamllint annotations/$STRAIN.$GNM.$ANN.$AKEY/MAN*yml
  yamllint genomes/$STRAIN.$GNM.$ANN.$AKEY/MAN*yml

# Compress and index
  compress_and_index.sh annotations/$STRAIN.$GNM.$ANN.$AKEY
  compress_and_index.sh genomes/$STRAIN.$GNM.$GKEY

# Calculate md5sum
  mdsum-folder.bash annotations/$STRAIN.$GNM.$ANN.$AKEY
  mdsum-folder.bash genomes/$STRAIN.$GNM.$GKEY

# Move to annex, for next steps by Andrew (AHRD and BUSCO)
  mkdir -p /project/legume_project/datastore/annex/$GENUS/$SP/annotations/
  mkdir -p /project/legume_project/datastore/annex/$GENUS/$SP/genomes/

  mv annotations/$STRAIN.$GNM.$ANN.$AKEY /project/legume_project/datastore/annex/$GENUS/$SP/annotations/
  mv genomes/$STRAIN.$GNM.$GKEY /project/legume_project/datastore/annex/$GENUS/$SP/genomes/

# Push the ds_souschef config to GitHub


