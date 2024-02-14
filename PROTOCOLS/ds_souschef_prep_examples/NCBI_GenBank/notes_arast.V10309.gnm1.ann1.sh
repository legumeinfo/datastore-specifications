# Objective: prepare assembly for Data Store. File-prep started 2019-09; i
# work on GenBank annotation ccontinued on 2023-12-19
# S. Cannon

# See the document here for detailed (general) instructions:
#   https://github.com/legumeinfo/datastore-specifications/tree/main/PROTOCOLS

# Data from https://www.ncbi.nlm.nih.gov/genome/annotation_euk/Arachis_stenosperma/GCF_014773155.1-RS_2023_06/
#RefSeq assembly GCF_014773155.1 (arast.V10309.gnm1.PFL2)
#https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_014773155.1/

cat << DONT_RUN_ME
This file contains notes for creating genome and annotation collections for the Data Store. Read them critically,
revise for your particular job, and copy-paste in an interactive terminal session. The file has a suffix ".sh"
only to get syntax highlighting in an editor (e.g. vim). It should not be executied as a shell script.
DONT_RUN_ME
echo; exit 1;

<< REFERENCE
[none]
REFERENCE

# NOTE: utility scripts are at /usr/local/www/data/datastore-specifications/scripts/
# If not added already to the PATH, do:
    PATH=/usr/local/www/data/datastore-specifications/scripts:$PATH 

# Variables for this job
  PRIVATE=   # Set this to the Data Store private root directory, i.e. ...data/private
  ACCN=GCF_014773155.1
  STRAIN=V10309
  GENUS=Arachis
  SP=stenosperma
  GENSP=arast
  GNM=gnm1
  ANN=ann1  
  GENOME=GCF_014773155.1_arast.V10309.gnm1.PFL2_genomic.fna
  CONFIGDIR=/usr/local/www/data/datastore-specifications/scripts/ds_souschef_configs
  FROM=$ACCN
  TO=derived

# NOTE: Get the keys with register_key.pl below !
  GKEY=PFL2
  AKEY=CZRZ

# Register new keys at peanutbase-stage:/usr/local/www/data/datastore-registry
# NOTE: Remember to fetch and pull before generating new keys.
  cd /usr/local/www/data/datastore-registry
  ./register_key.pl -v "$GENUS $SP genomes $STRAIN.$GNM"
  ./register_key.pl -v "$GENUS $SP annotations $STRAIN.$GNM.$ANN"
# NOTE: Remember to add, commit, and push the updated ds_registry.tsv  

# Make and cd into a work directory
  mkdir -p $PRIVATE/$GENUS/$SP
  cd $PRIVATE/$GENUS/$SP
  mkdir -p $STRAIN.$GNM.$ANN
  cd $STRAIN.$GNM.$ANN

# Get the genome assembly and annotations
  curl -O https://api.ncbi.nlm.nih.gov/datasets/v2alpha/genome/accession/GCF_014773155.1/download?include_annotation_type=GENOME_FASTA,GENOME_GFF,RNA_FASTA,CDS_FASTA,PROT_FASTA,SEQUENCE_REPORT

# Uncompress and move files into an easily accessible "from" directory
  unzip download
  mv ncbi_dataset/data/* .
  mv assembly_data_report.jsonl dataset_catalog.json GCF*/
  rm -rf ncbi_dataset/ download

# Prepare the data here:
  cd /usr/local/www/data/private/$GENUS/$SP/$STRAIN.$GNM.$ANN

# Make a directory for derived files if needed
  mkdir -p $TO $FROM

# Check the files.
# The assembly has the sequence wrapped lines with a width of 80 to permit subsequent indexing.

# Swap the chromosome/seq IDs and the ACCN IDs in the assembly,
# to get a defline like this:
#   >Chr1 GWHCAYC00000001 Complete=T Circular=F OriSeqID=Gm01 Len=59641292
  cat $FROM/$GENOME |
    perl -pe 's/^>(\S+)\s+.+chromosome (\d+), .+/>Chr$2 $1/;
              s/^>(\S+)\s+.+(Scaffold_\d+),.+/>$2 $1/' > $TO/$ACCN.modID.genome.fasta

# Also in the molecule IDs in the gff. 
# First, make an initial hash/map of the molecule IDs (ACCN and $FROM)
  grep '>' $FROM/$GENOME |
    perl -pe 's/^>(\S+)\s+.+chromosome (\d+), .+/$1\tChr$2/;
              s/^>(\S+)\s+.+(Scaffold_\d+),.+/$1\t$2/' > $TO/$ACCN.initial_seqid_map.tsv

# Simplify the GFF and replace GenBank's locus IDs with the base of the mRNA IDs
  hash_into_gff_id.pl -gff $FROM/genomic.gff -seqid_map $TO/$ACCN.initial_seqid_map.tsv |
    simplify_genbank_gff.sh | 
    rename_gff_mRNA_IDs.pl | 
    sort_gff.pl > $TO/$ACCN.modID.genes_exons.gff3

# Also make a version without exons (seems necessary for extracting transcript sequences with gffread)
  cat $TO/$ACCN.modID.genes_exons.gff3 | awk '$3!~/exon/' > $TO/$ACCN.modID.genes.gff3

# Remaining work in the work directory is in the "$TO" subdirectory
  cd $TO  

# Extract CDS, mRNA, and protein sequence. Note that this uses genes.gff3 rather than genes_exons.gff3
  gffread -g $ACCN.modID.genome.fasta \
          -w $ACCN.modID.transcripts.fna -x $ACCN.modID.CDS.fna -y $ACCN.modID.protein.faa \
            $ACCN.modID.genes.gff3

# Derive bed file
  cat $ACCN.modID.genes.gff3 | gff_to_bed7_mRNA.awk | sort -k1,1 -k2n,2n > $ACCN.modID.bed

# Derive primary/longest CDS, transcript, and protein sequences
  cat $ACCN.modID.transcripts.fna | longest_variant_from_fasta.sh > $ACCN.modID.transcripts_primary.fna &
  cat $ACCN.modID.CDS.fna | longest_variant_from_fasta.sh > $ACCN.modID.CDS_primary.fna &
  cat $ACCN.modID.protein.faa | longest_variant_from_fasta.sh > $ACCN.modID.protein_primary.faa &
  wait

# Compress the files
  for file in *gff3 *f?a *bed *.fasta; do 
    bgzip $file &
  done 

  rm *fai

# cd back to the main work directory
  cd $PRIVATE/$GENUS/$SP/$STRAIN.$GNM.$ANN

# Prepare the config for ds_souschef, in the datastore-specifications/scripts/ds_souschef_configs directory
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


