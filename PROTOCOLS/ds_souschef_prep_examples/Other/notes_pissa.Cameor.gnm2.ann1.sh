# Objective: Prepare assembly and annotation collection for Pisum sativum
# accession ZW6 (Zhongwan6)
# Started on 2025-04-08 (Steven Cannon)

# See the document here for detailed (general) instructions:
#   https://github.com/legumeinfo/datastore-specifications/tree/main/PROTOCOLS/README.md

cat << DONT_RUN_ME
This file contains notes for creating genome and annotation collections for the Data Store. Read them critically,
revise for your particular job, and copy-paste in an interactive terminal session. The file has a suffix ".sh"
only to get syntax highlighting in an editor (e.g. vim). It should not be executied as a shell script.
DONT_RUN_ME
echo; exit 1;

<< REFERENCE
Shenghan Gao. (2022). Genome assembly and annotation of Pisum sativum cultivar ZW6 (PeaZW6) (PeaZW6 Release Candidate v2.0) [Data set]. Zenodo. https://doi.org/10.5281/zenodo.6622409
REFERENCE

# Assembly was downloaded on 2024-04-08 from Zenodo
# https://doi.org/10.5281/zenodo.6622409
# https://zenodo.org/records/6622409

# NOTE: utility scripts are at /project/legume_project/datastore/datastore-specifications/scripts/
# If not added already to the PATH, do:
    PATH=/project/legume_project/datastore/datastore-specifications/scripts:$PATH

# Variables for this job
  PRIVATE=/project/legume_project/datastore/private/   # Set this to the Data Store private root directory: ...data/private/
  ACCN=GCF_024323335.1
  STRAIN=ZW6
  GENUS=Pisum
  SP=sativum
  GENSP=pissa
  GNM=gnm1
  ANN=ann1  
  GENOME=pea.assembly # The filename prefix common among all genome files in the source
  ANNOTATION=pea.assembly # The filename prefix ommon among all annotation files in the source
  CONFIGDIR=/project/legume_project/datastore/datastore-specifications/scripts/ds_souschef_configs

# NOTE: Get the keys with register_key.pl below !
  GKEY=D8R1
  AKEY=TKZX

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
  gffread -g pea.assembly.ZW6.RC2.genome.fna \
    -w pea.assembly.ZW6.RC2.annotated.transcripts.fna \
        pea.assembly.ZW6.RC2.annotated.gff3

# Derive primary/longest CDS, transcript, and protein sequences
#  cat pea.assembly.ZW6.RC2.annotated.cds.fna | longest_variant_from_fasta.sh > pea.assembly.ZW6.RC2.annotated.cds_primary.fna &
#  cat pea.assembly.ZW6.RC2.annotated.proteins.faa | longest_variant_from_fasta.sh > pea.assembly.ZW6.RC2.annotated.proteins_primary.faa &
#  cat pea.assembly.ZW6.RC2.annotated.transcripts.fna | longest_variant_from_fasta.sh > pea.assembly.ZW6.RC2.annotated.transcripts_primary.fna &
# NOTE: The longest_variant_from_fasta.sh method fails to find corresponding longest protein and CDS matches for three genes: 
#   comm -3 lis.*
#   >Psat01G0412100.T1
#     >Psat01G0412100.T2
#   >Psat05G0342200.T1
#     >Psat05G0342200.T2
#   >Psat05G0554300.T1
#     >Psat05G0554300.T2
#   
#   seqlen.awk pea.assembly.ZW6.RC2.annotated.cds.fna | grep Psat01G0412100
#   Psat01G0412100-T1 1050
#   Psat01G0412100-T2 1050
#   Psat01G0412100-T3 639
#   Psat01G0412100-T4 504
#   
#   seqlen.awk pea.assembly.ZW6.RC2.annotated.proteins.faa | grep Psat01G0412100
#   Psat01G0412100-T1 349
#   Psat01G0412100-T2 350
#   Psat01G0412100-T3 213
#   Psat01G0412100-T4 168

# So, instead use longest_variant_from_gff.pl


  cat pea.assembly.ZW6.RC2.annotated.gff3 | longest_variant_from_gff.pl > longest_variant.tsv
  cut -f3 longest_variant.tsv > lis.longest

  get_fasta_subset.pl -in *cds.fna -lis lis.longest -clobber -out pea.assembly.ZW6.RC2.annotated.cds_longest.fna
  get_fasta_subset.pl -in *proteins.faa -lis lis.longest -clobber -out pea.assembly.ZW6.RC2.annotated.proteins_longest.faa
  get_fasta_subset.pl -in *transcripts.fna -lis lis.longest -clobber -out pea.assembly.ZW6.RC2.annotated.transcripts_longest.fna


# Compress the files
  for file in *.f?a *.gff3; do
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
  tabix --csi annotations/ZW6.gnm1.ann1.TKZX/*gene_models_main.gff3.gz


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

