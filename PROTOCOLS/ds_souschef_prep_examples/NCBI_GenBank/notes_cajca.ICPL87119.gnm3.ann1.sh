# Objective: prepare assembly for Data Store. File-prep started 2026-09-01
# run on ceres.scinet.usda.gov
# W. Huang, S. Cannon

# See the document here for detailed (general) instructions:
#   https://github.com/legumeinfo/datastore-specifications/tree/main/PROTOCOLS

# Data from https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_000230855.2
#  Genome assembly NIPB_CcT2T_4

cat << DONT_RUN_ME
This file contains notes for creating genome and annotation collections for the Data Store. Read them critically,
revise for your particular job, and copy-paste in an interactive terminal session. The file has a suffix ".sh"
only to get syntax highlighting in an editor (e.g. vim). It should not be executied as a shell script.
DONT_RUN_ME
echo; exit 1;

<< REFERENCE
Singh,N.K., Gupta,D.K., Jayaswal,P.K., Mahato,A.K., Dutta,S.,Singh,S., Bhutani,S., Dogra,V., Singh,B.P., Kumawat,G., Jitendra, Pal,K., Pandit,A., Singh,A., Rawal,H., Kumar,A., Prashat,R., Khare,A., Yadav,R., Raje,R.S., Singh,M.N., Datta,S., Fakrudin,B., Wanjari,K.B., Kansal,R., Dash,P.K., Jain,P.K., Bhattacharya,R., Gaikwad,K., Mohapatra,T., Srinivasan,R. and Sharma,T.R. A telomere to telomere reference genome assembly of Cajanus cajan cv. Asha. Unpublished.
REFERENCE

# NOTE: utility scripts are at /project/legume_project/datastore/datastore-specifications/scripts/
# If not added already to the PATH, do:
    PATH=/project/legume_project/datastore/datastore-specifications/scripts:$PATH 

# Variables for this job
  PRIVATE=/project/legume_project/datastore/private  # Set this to the Data Store private root directory, i.e. ...data/private
  ACCN=GCF_000230855.2
  STRAIN=ICPL87119
  GENUS=Cajanus
  SP=cajan
  GENSP=cajca
  GNM=gnm3
  ANN=ann1  
  GENOME=GCF_000230855.2_NIPB_CcT2T_4_genomic.fna
  CONFIGDIR=/project/legume_project/datastore/datastore-specifications/scripts/ds_souschef_configs
  FROM=$ACCN
  TO=derived

# NOTE: Get the keys with register_key.pl below !
  GKEY=M6J1
  AKEY=3JT5

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
  curl -O "https://api.ncbi.nlm.nih.gov/datasets/v2/genome/accession/GCF_000230855.2/download?include_annotation_type=GENOME_FASTA&include_annotation_type=GENOME_GFF&include_annotation_type=RNA_FASTA&include_annotation_type=CDS_FASTA&include_annotation_type=PROT_FASTA&include_annotation_type=SEQUENCE_REPORT&hydrated=FULLY_HYDRATED"


# Uncompress and move files into an easily accessible "from" directory
  unzip 'download?include_annotation_type=GENOME_FASTA&include_annotation_type=GENOME_GFF&include_annotation_type=RNA_FASTA&include_annotation_type=CDS_FASTA&include_annotation_type=PROT_FASTA&include_annotation_type=SEQUENCE_REPORT&hydrated=FULLY_HYDRATED'
  mv ncbi_dataset/data/* .
  mv assembly_data_report.jsonl dataset_catalog.json GC*/
  rm -rf ncbi_dataset/
  rm 'download?include_annotation_type=GENOME_FASTA&include_annotation_type=GENOME_GFF&include_annotation_type=RNA_FASTA&include_annotation_type=CDS_FASTA&include_annotation_type=PROT_FASTA&include_annotation_type=SEQUENCE_REPORT&hydrated=FULLY_HYDRATED'

# Prepare the data here:
  cd $PRIVATE/$GENUS/$SP/$STRAIN.$GNM.$ANN

# Make a directory for derived files if needed
  mkdir -p $TO $FROM

# Check the files.
# The assembly has the sequence wrapped lines with a width of 80 to permit subsequent indexing.

# Swap the chromosome/seq IDs and the ACCN IDs in the assembly,
# to get a defline like this:
#   >Chr1 GWHCAYC00000001 Complete=T Circular=F OriSeqID=Gm01 Len=59641292
  cat $FROM/$GENOME |
    perl -pe 's/^>(\S+)\s+.+chromosome (\d+), .+/>Chr$2 $1/;
              s/^>(\S+)\s+.+(chloroplast),.+/>$2 $1/' |
      perl -pe 's/>Chr(\d) />Chr0$1 /; s/chloroplast/Chloroplast/' > $TO/$ACCN.modID.genome.fasta

# Also in the molecule IDs in the gff. 
# First, make an initial hash/map of the molecule IDs, e.g. NC_138517.1 Chr1
  grep '>' $FROM/$GENOME |
    perl -pe 's/^>(\S+)\s+.+chromosome (\d+), .+/$1\tChr$2/;
              s/^>(\S+)\s+.+(chloroplast),.+/$1\t$2/' |
      perl -pe 's/Chr(\d)$/Chr0$1/; s/chloroplast/Chloroplast/' > $TO/$ACCN.initial_seqid_map.tsv

# Simplify the GFF and replace GenBank's locus IDs with the base of the mRNA IDs.
# Also exclude the chloroplast, which is causing problems for rename_gff_mRNA_IDs.pl
# For symbol-based names with slashes, change slash to underscore, e.g. KT2/3 --> KT2/3 or FMN/FHY --> FMN_FHY
# and change the URL-encoded semicolon (%3B) to dash, e.g. SULTR3%3B5 --> SULTR3-B5 or CYCH%3B1 --> CYCH-B1
  hash_into_gff_id.pl -gff $FROM/genomic.gff -seqid_map $TO/$ACCN.initial_seqid_map.tsv |
    grep -v Chloroplast | 
    perl -lane '@first=@F[0..7]; $ninth=$F[8]; $ninth=~s{/}{_}g; $ninth=~s{%3B}{-}g; print join("\t", @first, $ninth);' |
    simplify_genbank_gff.sh > $TO/tmp.modID.simplified.gff

  ## testing rename_gff_mRNA_IDs.pl
  #  grep -v "^#" $TO/tmp.modID.simplified.gff | head -2000 > test.gff
  #  cat test.gff | rename_gff_mRNA_IDs.pl -v -x "cDNA_match|pseudogene|region|lncRNA|lnc_RNA|snRNA|snoRNA|transcript|tRNA|rRNA" \
  #    -out test.renamed.gff -rest test.noncoding.gff 2> test.rename.errout 1> test.rename.out 
  #    # check LOC145953854

# The script rename_gff_mRNA_IDs.pl can take an hour or two to run, so run the following in a slurm script.
# Check rename.errout for errors.
    cat $TO/tmp.modID.simplified.gff | rename_gff_mRNA_IDs.pl \
      -v -x "cDNA_match|pseudogene|region|lncRNA|lnc_RNA|snRNA|snoRNA|transcript|tRNA|rRNA" \
      -out $TO/tmp.modID.simplified.renamed.gff -rest $TO/tmp.modID.simplified.renamed.noncoding.gff 2> rename.errout 1> rename.out  

# Sort GFF 
  cat $TO/tmp.modID.simplified.renamed.gff | sort_gff.pl > $TO/$ACCN.modID.genes_exons.gff3
  cat $TO/tmp.modID.simplified.renamed.noncoding.gff | sort_gff.pl > $TO/$ACCN.modID.noncoding.gff3

# Remaining work in the work directory is in the "$TO" subdirectory
  cd $TO  
# to use gffread
  ml miniconda
  source activate ds-curate

# Extract CDS, mRNA, and protein sequence. 
# The flag "-C" indicates coding only; discard mRNAs that have no CDS features. 
# Among other effects, this suppresses duplicate transcripts in cases where # there are noncoding exons.
  gffread -g $ACCN.modID.genome.fasta -C \
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
  cd $PRIVATE/$GENUS/$SP/$STRAIN.$GNM.$ANN

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


