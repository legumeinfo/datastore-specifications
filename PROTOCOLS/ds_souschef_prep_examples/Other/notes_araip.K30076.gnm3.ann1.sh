# Objective: Prepare assembly and annotation collection for Arachis ipaensis
# accession K30076
# Started on 2026-10-07 (Steven Cannon)

# See the document here for detailed (general) instructions:
#   https://github.com/legumeinfo/datastore-specifications/tree/main/PROTOCOLS/README.md

cat << DONT_RUN_ME
This file contains notes for creating genome and annotation collections for the Data Store. Read them critically,
revise for your particular job, and copy-paste in an interactive terminal session. The file has a suffix ".sh"
only to get syntax highlighting in an editor (e.g. vim). It should not be executied as a shell script.
DONT_RUN_ME
echo; exit 1;

<< REFERENCE
Bian J, Zhang Y, Ding S, Guo H, Li K, Guan Y, Zhou G, Li J, Garg V, Cui Y, Lv Y, Chitikineni A, Meng Q, Li T, He L, Zhao C, Wang X, Tang R, Zhang L, Deng XW, Varshney RK, He H, Liu X. Telomere-to-telomere genome assemblies and population resequencing of diploid and allotetraploid peanut varieties. Nat Genet. 2026 May;58(5):1151-1163. doi: 10.1038/s41588-026-02577-z. Epub 2026 Apr 24. PMID: 42032297; PMCID: PMC13175896.
REFERENCE

# Assembly was downloaded on 2026-10-06 from https://figshare.com/articles/dataset/T2T_genome_assembly_in_peanut/28883636
# https://doi.org/10.6084/m9.figshare.28883636

# NOTE: utility scripts are at /project/legume_project/datastore/datastore-specifications/scripts/
# If not added already to the PATH, do:
    PATH=/project/legume_project/datastore/datastore-specifications/scripts:$PATH

# This collection is one of six described in Bian_Zhang_2026: one each for duranensis and ipaensis, and four for hypogaea.
# Do the preparation work for all three species in the pangene collection at
# /project/legume_project/datastore/private/Arachis/Bian_Zhang_2026
  PAN_GROUP=Bian_Zhang_2026

# Variables for this job
  PRIVATE=/project/legume_project/datastore/private/   # Set this to the Data Store private root directory: ...data/private/
  ACCN=GCA_040739545.1
  STRAIN=K30076
  GENUS=Arachis
  SP=ipaensis
  GENSP=araip
  GNM=gnm3
  ANN=ann1  
  GENOME=$PAN_GROUP. # The filename prefix common among all genome files in the source
  ANNOTATION=$PAN_GROUP. # The filename prefix ommon among all annotation files in the source
  CONFIGDIR=/project/legume_project/datastore/datastore-specifications/scripts/ds_souschef_configs

# NOTE: Get the keys with register_key.pl below !
  GKEY=54MN
  AKEY=ZVKP

# Register new keys at /project/legume_project/datastore/datastore-registry
# NOTE: Remember to fetch and pull before generating new keys.
  cd /project/legume_project/datastore/datastore-registry
  ./register_key.pl -v "$GENUS $SP genomes $STRAIN.$GNM"
  ./register_key.pl -v "$GENUS $SP annotations $STRAIN.$GNM.$ANN"
# NOTE: Remember to add, commit, and push the updated ds_registry.tsv  

# Make and cd into a work directory
# Note: this is different from most collections, because it is a pangene collection, comprising three species
  mkdir -p $PRIVATE/$GENUS/$PAN_GROUP
  cd $PRIVATE/$GENUS/$PAN_GROUP

  mkdir -p original derived

# Download the assembly and annotation files (using curl)

# Check the files. If the assembly sequence is not wrappeed (to permit indexing), fix this.
# Also check the form of the chromosome and scaffold names.

# The IDs and Names look like:
#   gene  ID=evm.TU.chr01.3;Name=EVM%2520prediction%2520chr01.3
#   mRNA  ID=evm.model.chr01.3;Name=EVM%2520prediction%2520chr01.3;Parent=evm.TU.chr01.3
# Transform them like so:
#   gene  ID=evm.TU.chr01.3;Name=evm_chr01.3
#   mRNA  ID=evm.model.chr01.3.1;Name=evm_chr01.3.1;Parent=evm.chr01.3

  zcat original/$STRAIN.genome.fa.gz > derived/$PAN_GROUP.$STRAIN.genome.fna

  zcat original/$STRAIN.gff.gz |
    perl -pe 's/EVM%2520prediction%2520/evm_/; s/evm\.model\./evm_/g; s/evm\.TU\./evm_/' |
    perl -lane '$ninth=$F[8];
                 $ninth =~ s/(chr\d+)\.(\d+)/$1_$2/g;
                 if ($F[2] =~ /gene/) {
                   # do nothing
                 }
                 elsif ($F[2] =~ /mRNA/) {
                   $ninth =~ s/ID=(evm_chr\d+_\d+)/ID=$1.1/;
                   $ninth =~ s/Name=(evm_chr\d+_\d+)/Name=$1.1/;
                 }
                 else {
                   $ninth =~ s/ID=(evm_chr\d+_\d+)/ID=$1.1/;
                   $ninth =~ s/Parent=(evm_chr\d+_\d+)/Parent=$1.1/;
                 }
                 print join("\t", @F[0..7], $ninth);
               ' | sort_gff.pl > derived/$PAN_GROUP.$STRAIN.gff3

# Extract CDS, protein, and transcript sequences
  cd derived

  gffread -g $PAN_GROUP.$STRAIN.genome.fna \
          -w $PAN_GROUP.$STRAIN.transcript.fna \
          -x $PAN_GROUP.$STRAIN.CDS.fna \
          -y $PAN_GROUP.$STRAIN.protein.faa \
             $PAN_GROUP.$STRAIN.gff3

# Check results:
  grep -c '>' *.f?a
  # Feature counts are the same for proteins, transcripts, and CDS, so there are no noncoding genes.

# Derive primary/longest CDS, transcript, and protein sequences
# (There is only one splice variant per gene, but derive them anyway for file consistency)
  cat $PAN_GROUP.$STRAIN.CDS.fna | longest_variant_from_fasta.sh > $PAN_GROUP.$STRAIN.CDS_primary.fna
  cat $PAN_GROUP.$STRAIN.protein.faa | longest_variant_from_fasta.sh > $PAN_GROUP.$STRAIN.protein_primary.faa
  cat $PAN_GROUP.$STRAIN.transcript.fna | longest_variant_from_fasta.sh > $PAN_GROUP.$STRAIN.transcript_primary.fna

# Derive bed file
  cat $PAN_GROUP.$STRAIN.gff3 | gff_to_bed7_mRNA.awk | sort -k1,1 -k2n,2n > $PAN_GROUP.$STRAIN.bed

# Compress the files
  rm *.fai

  for file in *f?a *gff3  *bed; do
    bgzip -l9 $file &
  done

# Prepare the config for ds_souschef. Typically, copy from a similar config file and revise.
  cd $PRIVATE/$GENUS/$PAN_GROUP

  vim $CONFIGDIR/$PAN_GROUP/$GENSP.$STRAIN.$GNM.$ANN.yml

# Run ds_souschef.pl with the config above
  ds_souschef.pl -config $CONFIGDIR/$PAN_GROUP/$GENSP.$STRAIN.$GNM.$ANN.yml

# NOTE: Check the results for sanity.
# The fasta files (cds, transcript, protein) should all have prefixes (gensp.genotype.gnm#.ann#.)
# If there are any cases of "HASH UNDEFINED", then check whether the gff "strip" step produced the desired result.
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

