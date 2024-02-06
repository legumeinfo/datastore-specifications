# Objective: Prepare assembly and annotation collection for Glycine max accession 
# Wm82 from Nanjing Agricultural University / Wm82-NJAU
# Started on 2023-12-01 (JDC, SBC)

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
Wang L, Zhang M, Li M, Jiang X, Jiao W, Song Q. A telomere-to-telomere gap-free assembly of soybean genome. Mol Plant. 2023 Nov 6;16(11):1711-1714. doi: 10.1016/j.molp.2023.08.012. Epub 2023 Aug 26. PMID: 37634078.
REFERENCE

# Assembly was downloaded on 2023-11-21 from Genome Warehouse
# https://ngdc.cncb.ac.cn/gwh/Assembly/37536/show

# NOTE: utility scripts are at /usr/local/www/data/datastore-specifications/scripts/
# If not added already to the PATH, do:
    PATH=/usr/local/www/data/datastore-specifications/scripts:$PATH 

# Variables for this job
  PRIVATE=   # Set this to the Data Store private root directory, i.e. ...data/private/
  ACCN=GWHCAYC00000000
  STRAIN=Wm82_NJAU
  GENUS=Glycine
  SP=max
  GENSP=glyma
  GNM=gnm1
  ANN=ann1  
  GENOME=GWHCAYC00000000.genome.fasta
  CONFIGDIR=/usr/local/www/data/datastore-specifications/scripts/ds_souschef_configs
  FROM=$ACCN
  TO=derived

# Register new keys at peanutbase-stage:/usr/local/www/data/datastore-registry
# NOTE: Remember to fetch and pull before generating new keys.
  cd /usr/local/www/data/datastore-registry
  ./register_key.pl -v "$GENUS $SP genomes $STRAIN.$GNM"
  ./register_key.pl -v "$GENUS $SP annotations $STRAIN.$GNM.$ANN"
# NOTE: Remember to add, commit, and push the updated ds_registry.tsv  
  GKEY=N4GV
  AKEY=KM71

# Make and cd into a work directory
  mkdir -p $PRIVATE/$GENUS/$SP
  cd $PRIVATE/$GENUS/$SP
  mkdir $STRAIN.$GNM.$ANN
  cd $STRAIN.$GNM.$ANN

# Put the original files in original/ and manually derived files in derived/
  mkdir -p $TO $FROM

# Check the files.
# The assembly has the sequence wrapped lines with a width of 100 to permit subsequent indexing.

# Swap the chromosome/seq IDs and the ACCN IDs in the assembly,
# to get a defline like this:
#   >Chr1 GWHCAYC00000001 Complete=T Circular=F OriSeqID=Gm01 Len=59641292
  zcat $FROM/$ACCN.genome.fasta.gz | 
    perl -pe 's/^>(\S+)\s+.+SeqID=(\w+)\s+Len=(\d+)/>$2 $1 Len=$3/' > $TO/$ACCN.modID.genome.fasta

# Also in the molecule IDs in the gff. 
# First, make an initial hash/map of the molecule IDs (ACCN and $FROM)
  zcat $FROM/$ACCN.gff.gz | 
    awk '$1~/^#OriSeqID/ {print substr($2, 11) "\t" substr($1, 11)}' > $TO/$ACCN.initial_seqid_map.tsv

  hash_into_gff_id.pl -gff $FROM/$ACCN.gff.gz -seqid_map $TO/$ACCN.initial_seqid_map.tsv |
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

