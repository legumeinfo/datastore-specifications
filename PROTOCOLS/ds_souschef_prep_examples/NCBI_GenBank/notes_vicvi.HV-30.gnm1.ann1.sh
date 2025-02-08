# Objective: prepare assembly for Data Store. File-prep started 2024-03-01
# work on GenBank annotation ccontinued on 2024-03-01
# S. Cannon

# See the document here for detailed (general) instructions:
#   https://github.com/legumeinfo/datastore-specifications/tree/main/PROTOCOLS

# Data from https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_029867415.1/ 
#RefSeq assembly  GCF_029867415.1 (vicvi.HV-30.gnm1.2TXG)

cat << DONT_RUN_ME
This file contains notes for creating genome and annotation collections for the Data Store. Read them critically,
revise for your particular job, and copy-paste in an interactive terminal session. The file has a suffix ".sh"
only to get syntax highlighting in an editor (e.g. vim). It should not be executied as a shell script.
DONT_RUN_ME
echo; exit 1;

<< REFERENCE
Fuller T, Bickhart DM, Koch LM, Kucek LK, Ali S, Mangelson H, Monteros MJ, Hernandez T, Smith TPL, Riday H, Sullivan ML. 
A reference assembly for the legume cover crop hairy vetch (Vicia villosa). GigaByte. 2023 Nov 13;2023:gigabyte98. 
doi: 10.46471/gigabyte.98. PMID: 38023065; PMCID: PMC10659084.
REFERENCE

# NOTE: utility scripts are at /project/legume_project/datastore/datastore-specifications/scripts/
# If not added already to the PATH, do:
    PATH=/project/legume_project/datastore/datastore-specifications/scripts:$PATH 

# Variables for this job
  PRIVATE=/project/legume_project/datastore/private   # Set this to the Data Store private root directory, i.e. ...data/private
  ACCN=GCF_029867415.1
  STRAIN=HV-30
  GENUS=Vicia
  SP=villosa
  GENSP=vicvi
  GNM=gnm1
  ANN=ann1  
  GENOME=GCF_029867415.1_Vvil1.0_genomic.fna
  CONFIGDIR=/project/legume_project/datastore/datastore-specifications/scripts/ds_souschef_configs
  FROM=$ACCN
  TO=derived

# NOTE: Get the keys with register_key.pl below !
  GKEY=2TXG
  AKEY=6WFF

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
 curl -O https://api.ncbi.nlm.nih.gov/datasets/v2alpha/genome/accession/GCF_029867415.1/download?include_annotation_type=GENOME_FASTA,GENOME_GFF,RNA_FASTA,CDS_FASTA,PROT_FASTA,SEQUENCE_REPORT

# Uncompress and move files into an easily accessible "from" directory
  unzip download
  mv ncbi_dataset/data/* .
  mv assembly_data_report.jsonl dataset_catalog.json GCF*/
  rm -rf ncbi_dataset/ download

# Prepare the data here:
  cd /project/legume_project/datastore/private/$GENUS/$SP/$STRAIN.$GNM.$ANN

# Make a directory for derived files if needed
  mkdir -p $TO $FROM

# Check the files.
# The assembly has the sequence wrapped lines with a width of 80 to permit subsequent indexing.

# Swap the chromosome/seq IDs and the ACCN IDs in the assembly,
# to get a defline like this:
#   >Chr1 GWHCAYC00000001 Complete=T Circular=F OriSeqID=Gm01 Len=59641292
  cat $FROM/$GENOME |
    perl -pe 's/^>(\S+)\s+.+LG(\d+), .+/>Chr$2 $1/;
              s/^>(\S+)\s+.+(ctg.\S+),.+/>$2 $1/;
              s/^>(\S+)\s+.+(scaffold\d+),.+/>$2 $1/' > $TO/$ACCN.modID.genome.fasta

# Also in the molecule IDs in the gff. 
# First, make an initial hash/map of the molecule IDs (ACCN and $FROM)
  grep '>' $FROM/$GENOME |
    perl -pe 's/^>(\S+)\s+.+LG(\d+), .+/$1\tChr$2/;
              s/^>(\S+)\s+.+(ctg.\S+),.+/$1\t$2/;
              s/^>(\S+)\s+.+(scaffold\d+),.+/$1\t$2/' > $TO/$ACCN.initial_seqid_map.tsv

# Simplify the GFF and replace GenBank's locus IDs with the base of the mRNA IDs.
# Also remove MT and Pltd records (which lack strand information so cause errors with gffread)
# NOTE: This step takes LONG time (perhaps 6-8 hours), so run it with nohup and in the background.
  hash_into_gff_id.pl -gff $FROM/genomic.gff -seqid_map $TO/$ACCN.initial_seqid_map.tsv |
    simplify_genbank_gff.sh | awk '$1!~/Pltd/ && $1!~/^MT/' > tmp.modID.simplified.gff

  nohup cat tmp.modID.simplified.gff |
    rename_gff_mRNA_IDs.pl -x "lnc_RNA,pseudogene,region,tRNA,snoRNA,snRNA,rRNA" -out tmp.modID.simplified.renamed.gff \
      -rest tmp.modID.simplified.renamed.noncoding.gff 2> nohup_rename.errout 1> nohup_rename.out &

# Sort GFF 
  cat tmp.modID.simplified.renamed.gff | awk '$1!~/MT/ && $1!~/Pltd/' | sort_gff.pl > $TO/$ACCN.modID.genes_exons.gff3
  cat tmp.modID.simplified.renamed.noncoding.gff | awk '$1!~/MT/ && $1!~/Pltd/' | sort_gff.pl > $TO/$ACCN.modID.noncoding.gff3

# Remaining work in the work directory is in the "$TO" subdirectory
  cd $TO

# Extract CDS, mRNA, and protein sequence. 
  gffread -g $ACCN.modID.genome.fasta \
          -w $ACCN.modID.transcripts.fna -x $ACCN.modID.CDS.fna -y $ACCN.modID.protein.faa \
            $ACCN.modID.genes_exons.gff3

# Derive bed file
  cat $ACCN.modID.genes_exons.gff3 | gff_to_bed7_mRNA.awk | sort -k1,1 -k2n,2n > $ACCN.modID.bed

# Derive primary/longest CDS, transcript, and protein sequences
  cat $ACCN.modID.transcripts.fna | longest_variant_from_fasta.sh > $ACCN.modID.transcripts_primary.fna &
  cat $ACCN.modID.CDS.fna | longest_variant_from_fasta.sh > $ACCN.modID.CDS_primary.fna &
  cat $ACCN.modID.protein.faa | longest_variant_from_fasta.sh > $ACCN.modID.protein_primary.faa &
  wait

# Compress the files
  for file in *gff3 *f?a *bed *.fasta; do 
    bgzip $file &
  done 
  wait

  rm *fai

# cd back to the main work directory
  cd $PRIVATE/$GENUS/$SP/$STRAIN.$GNM.$ANN


# Prepare the config for ds_souschef, in the datastore-specifications/scripts/ds_souschef_configs directory
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


