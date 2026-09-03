# Objective: prepare assembly for Data Store. File-prep started 2026-08-12
# run on ceres.scinet.usda.gov
# W.Huang

# See the document here for detailed (general) instructions:
#   https://github.com/legumeinfo/datastore-specifications/tree/main/PROTOCOLS

# Data from https://www.ncbi.nlm.nih.gov/datasets/genome/GCA_963859935.3/
#  RefSeq assembly  GCA_963859935.3, assembly JIC_Lsat_v2.1.1

cat << DONT_RUN_ME
This file contains notes for creating genome and annotation collections for the Data Store. Read them critically,
revise for your particular job, and copy-paste in an interactive terminal session. The file has a suffix ".sh"
only to get syntax highlighting in an editor (e.g. vim). It should not be executied as a shell script.
DONT_RUN_ME
echo; exit 1;

<< REFERENCE
Marielle Vigouroux, Petr Novák, Ludmila Cristina Oliveira, Carmen Santos, Jitender Cheema, Roland H. M. Wouters, Pirita Paajanen, Martin Vickers, Andrea Koblížková, Maria Carlota Vaz Patto, Jiří Macas, Burkhard Steuernagel, Cathie Martin & Peter M. F. Emmrich, A chromosome-scale reference genome of grasspea (Lathyrus sativus). Sci Data. 2024 Sep 27;11(1):1035. doi: 10.1038/s41597-024-03868-y. PMID: 39333203  PMCID: PMC11437036.
REFERENCE

# NOTE: utility scripts are at /project/legume_project/datastore/datastore-specifications/scripts/
# If not added already to the PATH, do:
    PATH=/project/legume_project/datastore/datastore-specifications/scripts:$PATH 

# Variables for this job
  PRIVATE=/project/legume_project/datastore/private  # Set this to the Data Store private root directory, i.e. ...data/private
  ACCN=GCA_963859935.3
  STRAIN=LS007
  GENUS=Lathyrus
  SP=sativus
  GENSP=latsa
  GNM=gnm2
  ANN=ann1  
  GENOME=GCA_963859935.3_JIC_Lsat_v2.1.1_genomic.fna
  CONFIGDIR=/project/legume_project/datastore/datastore-specifications/scripts/ds_souschef_configs
  FROM=$ACCN
  TO=derived

# NOTE: Get the keys with register_key.pl below !
  GKEY=DQN8
  AKEY=SQLB

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
  curl -O curl -O "https://api.ncbi.nlm.nih.gov/datasets/v2/genome/accession/GCA_963859935.3/download?include_annotation_type=GENOME_FASTA&include_annotation_type=GENOME_GFF&include_annotation_type=RNA_FASTA&include_annotation_type=CDS_FASTA&include_annotation_type=PROT_FASTA&include_annotation_type=SEQUENCE_REPORT&hydrated=FULLY_HYDRATED" 

# Uncompress and move files into an easily accessible "from" directory
  unzip 'download?include_annotation_type=GENOME_FASTA&include_annotation_type=GENOME_GFF&include_annotation_type=RNA_FASTA&include_annotation_type=CDS_FASTA&include_annotation_type=PROT_FASTA&include_annotation_type=SEQUENCE_REPORT&hydrated=FULLY_HYDRATED'
  mv ncbi_dataset/data/* .
  mv assembly_data_report.jsonl dataset_catalog.json GC*/

# Prepare the data here:
  cd $PRIVATE/$GENUS/$SP/$STRAIN.$GNM.$ANN

# Make a directory for derived files if needed
  mkdir -p $TO $FROM

# Check the files.
# The assembly has the sequence wrapped lines with a width of 80 to permit subsequent indexing.

# Swap the chromosome/seq IDs and the ACCN IDs in the assembly,
# to get a defline like this:
#   >Chr1 GWHCAYC00000001 Complete=T Crcular=F OriSeqID=Gm01 Len=59641292

  cat $FROM/$GENOME |
    perl -pe 's/^>(\S+)\s+.+chromosome:\s+(\d+)/>Chr0$2 $1/; s/^>(\S+)\s+.+HiC_(scaffold_\d+),.+/>$2 $1/' > $TO/$ACCN.modID.genome.fasta 
    
# Also in the molecule IDs in the gff. 
  grep ">"  $FROM/$GENOME |
    perl -pe 's/^>(\S+)\s+.+chromosome:\s+(\d+)/$1 Chr0$2/; s/^>(\S+)\s+.+HiC_(scaffold_\d+),.+/$1 $2/'> $TO/$ACCN.initial_seqid_map.tsv


# genomic.gff has "intron" lines for type, so remove these lines 
  cat $FROM/genomic.gff | grep -v "^#" | perl -pe 's/.+\s+intron.+\n//; s/.+\s+region.+\n//' > $TO/$ACCN.genomic.mod.gff

# Simplify the GFF and replace GenBank's locus IDs with the base of the mRNA IDs.
  cd /project/legume_project/datastore/private/$GENUS/$SP/$STRAIN.$GNM.$ANN

  # Remove type prefixes from IDs.
  # Add a splice variant digit to the first one (previously, the first variant was bare and the second was "-2"
  # Change from a dash separator for the splice variant to a dot, e.g. LATHSAT_LOCUS25160-2 --> LATHSAT_LOCUS25160.2

  hash_into_gff_id.pl -gff $FROM/genomic.gff -seqid_map $TO/$ACCN.initial_seqid_map.tsv |
    simplify_genbank_gff.sh | awk '$1!~/##sequence|##species/ && $3!~/intron|region/' |
    perl -pe 's/cds-//g; s/rna-//g; s/gene-//g; s/exon-//g; s/id-//g' |
    perl -pe 's/(LATHSAT_LOCUS\d+)-(\d+)/$1.$2/g' |
    perl -lane 'if ($F[2] =~ /mRNA/ && $F[8] =~ /ID=(LATHSAT_LOCUS\d+);/) { 
                    $ninth=$F[8]; $ninth = "ID=$1.1;Parent=$1;Name=$1.1";
                    print join("\t", @F[0..7], $ninth);
                }
                elsif ($F[2] !~ /mRNA/ && $F[8] =~ /Parent=(LATHSAT_LOCUS\d+);/) { 
                    $ninth=$F[8]; $ninth =~ s/(LATHSAT_LOCUS\d+)/$1.1/g; 
                    print join("\t", @F[0..7], $ninth);
                }
                else {
                    print $_;
                }' |
    sort_gff.pl > $TO/$ACCN.modID.simplified.gff3

  # test with a gene that has multiple splice variants: LATHSAT_LOCUS25160


# Remaining work in the work directory is in the "$TO" subdirectory
  cd $TO  
# to use gffread
  ml miniconda
  source activate ds-curate

# Extract CDS, mRNA, and protein sequence. 
  gffread -g $ACCN.modID.genome.fasta \
          -w $ACCN.modID.transcripts.fna -x $ACCN.modID.CDS.fna -y $ACCN.modID.protein.faa \
             $ACCN.$ACCN.modID.simplified.gff3

# Derive bed file
  cat $ACCN.modID.simplified.gff | gff_to_bed7_mRNA.awk | sort -k1,1 -k2n,2n > $ACCN.modID.bed

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

# modified *gff3 that produced by ds_souschef.pl
#remove gene- for the gene type, arrange the cds and exon 9th columns

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

#  [E::hts_idx_check_range] Region 537673931..537674303 cannot be stored in a tbi index. Try using a csi index
  tabix -C -p gff annotations/$STRAIN.$GNM.$ANN.$AKEY/*.gene_models_main.gff3.gz 

# Calculate md5sum
  mdsum-folder.bash annotations/$STRAIN.$GNM.$ANN.$AKEY
  mdsum-folder.bash genomes/$STRAIN.$GNM.$GKEY

# Move to annex, for next steps by Andrew (AHRD and BUSCO)
  mkdir -p /project/legume_project/datastore/annex/$GENUS/$SP/annotations/
  mkdir -p /project/legume_project/datastore/annex/$GENUS/$SP/genomes/

  mv annotations/$STRAIN.$GNM.$ANN.$AKEY /project/legume_project/datastore/annex/$GENUS/$SP/annotations/
  mv genomes/$STRAIN.$GNM.$GKEY /project/legume_project/datastore/annex/$GENUS/$SP/genomes/

# Push the ds_souschef config to GitHub


