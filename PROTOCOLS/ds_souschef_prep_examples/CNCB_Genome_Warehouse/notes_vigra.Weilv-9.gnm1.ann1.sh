# Objective: Prepare assembly and annotation collection for Vigna radiata accession 
# Weilv-9 from Kunming Institute of Botany, Chinese Academy of Sciences
# Started on 2026-01-11 (Steven Cannon)

# See the document here for detailed (general) instructions:
#   https://github.com/legumeinfo/datastore-specifications/tree/main/PROTOCOLS/README.md

cat << DONT_RUN_ME
This file contains notes for creating genome and annotation collections for the Data Store. Read them critically,
revise for your particular job, and copy-paste in an interactive terminal session. The file has a suffix ".sh"
only to get syntax highlighting in an editor (e.g. vim). It should not be executied as a shell script.
DONT_RUN_ME
echo; exit 1;

<< REFERENCE
Jia KH, Li G, Wang L, Liu M, Wang ZW, Li RZ, Li LL, Xie K, Yang YY, Tian RM, Chen X, Si YJ, Zhang XY, Song FJ, Li L, Li NN. Telomere-to-telomere, gap-free genome of mung bean (Vigna radiata) provides insights into domestication under structural variation. Hortic Res. 2024 Dec 2;12(3):uhae337. doi: 10.1093/hr/uhae337. PMID: 40061812; PMCID: PMC11886820.
REFERENCE

# Assembly was downloaded on 2026-01-11 from Genome Warehouse
# https://ngdc.cncb.ac.cn/gwh/Assembly/83514/show
# accession GWHEQVC00000000

# Start a curation session on ceres
  salloc -A legume_project
  ml miniconda
  source activate ds-curate

# NOTE: utility scripts are at /project/legume_project/datastore/datastore-specifications/scripts/
# If not added already to the PATH, do:
    PATH=/project/legume_project/datastore/datastore-specifications/scripts:$PATH 

# Variables for this job
  PRIVATE=/project/legume_project/datastore/private   # Set this to the Data Store private root directory, i.e. ...data/private/
  ACCN=GWHEQVC00000000
  STRAIN=Weilv-9
  GENUS=Vigna
  SP=radiata
  GENSP=vigra
  GNM=gnm1
  ANN=ann1  
  GENOME=GWHEQVC00000000.genome.fasta.gz
  CONFIGDIR=/project/legume_project/datastore/datastore-specifications/scripts/ds_souschef_configs
  FROM=$ACCN
  TO=derived

# NOTE: Get the keys with register_key.pl below !
  GKEY=5TZZ
  AKEY=FPGC

# Register new keys at peanutbase-stage:/project/legume_project/datastore/datastore-registry
# NOTE: Remember to fetch and pull before generating new keys.
  cd /project/legume_project/datastore/datastore-registry
  ./register_key.pl -v "$GENUS $SP genomes $STRAIN.$GNM"
  ./register_key.pl -v "$GENUS $SP annotations $STRAIN.$GNM.$ANN"
# NOTE: Remember to add, commit, and push the updated ds_registry.tsv  

# Make and cd into a work directory
  mkdir -p $PRIVATE/$GENUS/$SP/$STRAIN.$GNM.$ANN
  cd $PRIVATE/$GENUS/$SP/$STRAIN.$GNM.$ANN

# Put the original files in original/ and manually derived files in derived/
  mkdir -p $TO $FROM

# Check the files.
# The assembly has the sequence wrapped lines with a width of 100 to permit subsequent indexing.

# Swap the chromosome/seq IDs and the ACCN IDs in the assembly,
#   >GWHEQVC00000001	Chromosome 1	Complete=F	Circular=F	OriSeqID=chr01	Len=41915861
# to get a defline like this:
#   >chr01 GWHEQVC00000001 Len=41915861
  zcat $FROM/$ACCN.genome.fasta.gz | 
    perl -pe 's/^>(\S+)\s+.+OriSeqID=(\S+)\s+Len=(\d+)/>$2 $1 Len=$3/' > $TO/$ACCN.modID.genome.fasta

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


#####
# cd back to the main work directory
  cd $PRIVATE/$GENUS/$SP/$STRAIN.$GNM.$ANN

# Prepare the config for ds_souschef 
  vim $CONFIGDIR/$GENSP.$STRAIN.$GNM.$ANN.yml
  
# Run ds_souschef.pl with the config above
  ds_souschef.pl -config $CONFIGDIR/$GENSP.$STRAIN.$GNM.$ANN.yml

# NOTE: Check the results for sanity.
# The fasta files (cds, transcript, protein) should all have prefixes (gensp.genotype.gnm#.ann#.)
  echo "Testing for hashing correctness. Counts of UNDEFINED should be 0 in all files."
  grep -c UNDEFINED annotations/$STRAIN.$GNM.$ANN.$AKEY/*


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
  mkdir -p /project/legume_project/datastore/annex/$GENUS/$SP/annotations/
  mkdir -p /project/legume_project/datastore/annex/$GENUS/$SP/genomes/

  mv annotations/$STRAIN.$GNM.$ANN.$AKEY /project/legume_project/datastore/annex/$GENUS/$SP/annotations/
  mv genomes/$STRAIN.$GNM.$GKEY /project/legume_project/datastore/annex/$GENUS/$SP/genomes/

# Push the ds_souschef config to GitHub

