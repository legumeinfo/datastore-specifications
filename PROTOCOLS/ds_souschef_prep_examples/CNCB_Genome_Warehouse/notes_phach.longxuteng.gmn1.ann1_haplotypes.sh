# Objective: Prepare assembly and annotation collection for Phanera championii accession 
# longxuteng from 	Guangxi University / longxuteng
# Started on 2024-02-02 (Hyunoh Lee, Steven Cannon)

# See the document here for detailed (general) instructions:
#   https://github.com/legumeinfo/datastore-specifications/tree/main/PROTOCOLS/README.md

cat << DONT_RUN_ME
This file contains notes for creating genome and annotation collections for the Data Store. Read them critically,
revise for your particular job, and copy-paste in an interactive terminal session. The file has a suffix ".sh"
only to get syntax highlighting in an editor (e.g. vim). It should not be executied as a shell script.
DONT_RUN_ME
echo; exit 1;

<< REFERENCE
Lu Y, Chen X, Yu H, Zhang C, Xue Y, Zhang Q, Wang H. Haplotype-resolved genome assembly of Phanera championii reveals molecular mechanisms of flavonoid synthesis and adaptive evolution. Plant J. 2024 Jan 3. doi: 10.1111/tpj.16620. Epub ahead of print. PMID: 38173092.
REFERENCE

# Assembly was downloaded on 2024-02-02 from Genome Warehouse
# https://ngdc.cncb.ac.cn/gwh/Assembly/68870/show

# NOTE: utility scripts are at /usr/local/www/data/datastore-specifications/scripts/
# If not added already to the PATH, do:
    PATH=/usr/local/www/data/datastore-specifications/scripts:$PATH 

# Variables for this job
  PRIVATE=/usr/local/www/data/private/   # Set this to the Data Store private root directory, i.e. ...data/private/
  ACCN=GWHCBFY00000000.1
  STRAIN=longxuteng
  GENUS=Phanera
  SP=championii
  GENSP=phach
  GNM=gnm1
  ANN=ann1  
  GENOME=GWHCBFY00000000.1.genome.fasta
  CONFIGDIR=/usr/local/www/data/datastore-specifications/scripts/ds_souschef_configs
  FROM=$ACCN
  TO=/usr/local/www/data/private/Phanera/championii

# NOTE: Get the keys with register_key.pl below !
  GKEY=WJG7
  AKEY=KGX9

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

# The assembly is in two haplotypes:
#   GWHCBFY00000001.1	Chr01_hap1
#   GWHCBFY00000015.1	Chr01_hap2
#   GWHCBFY00000002.1	Chr02_hap1
#   GWHCBFY00000016.1	Chr02_hap2

# Strategy: 
# Proceed as with other GWH data sets, then divide into two haplotype sets.

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

##########
# Special handling to split two haplotypes into two sets of files

# Split the assemblies into two files
  grep "_hap1" $ACCN.modID.genome.fasta | perl -pe 's/>(\S+) .+/$1/' > lis.chr_hap1 &
  grep "_hap2" $ACCN.modID.genome.fasta | perl -pe 's/>(\S+) .+/$1/' > lis.chr_hap2

  get_fasta_subset.pl -lis lis.chr_hap1 -in $ACCN.modID.genome.fasta -out $ACCN.hap1.modID.genome.fasta -clobber &
  get_fasta_subset.pl -lis lis.chr_hap2 -in $ACCN.modID.genome.fasta -out $ACCN.hap2.modID.genome.fasta -clobber 

  # Strip the _hap# strings
  perl -pi -e 's/_hap[12]//' $ACCN.hap?.modID.genome.fasta 

# Split the gff and bed files into two sets of files
  cat $ACCN.modID.bed | awk '$1~/_hap1/' | perl -pe 's/_hap[12]//' > $ACCN.hap1.modID.bed
  cat $ACCN.modID.bed | awk '$1~/_hap2/' | perl -pe 's/_hap[12]//' > $ACCN.hap2.modID.bed

  cat $ACCN.modID.genes.gff3 | awk '$1~/_hap1/' | perl -pe 's/_hap[12]//' > $ACCN.hap1.modID.genes.gff3
  cat $ACCN.modID.genes.gff3 | awk '$1~/_hap2/' | perl -pe 's/_hap[12]//' > $ACCN.hap2.modID.genes.gff3

  cat $ACCN.modID.genes_exons.gff3 | awk '$1~/_hap1/' | perl -pe 's/_hap[12]//' > $ACCN.hap1.modID.genes_exons.gff3
  cat $ACCN.modID.genes_exons.gff3 | awk '$1~/_hap2/' | perl -pe 's/_hap[12]//' > $ACCN.hap2.modID.genes_exons.gff3

# Split the initial_seqid_map
  cat $ACCN.initial_seqid_map.tsv | grep _hap1 | perl -pe 's/_hap[12]//' > $ACCN.hap1.initial_seqid_map.tsv
  cat $ACCN.initial_seqid_map.tsv | grep _hap2 | perl -pe 's/_hap[12]//' > $ACCN.hap2.initial_seqid_map.tsv

# Extract CDS, mRNA, and protein sequence from the two haplotypes
  for HAP in hap1 hap2; do
    gffread -g $ACCN.$HAP.modID.genome.fasta \
            -w $ACCN.$HAP.modID.transcripts.fna -x $ACCN.$HAP.modID.CDS.fna -y $ACCN.$HAP.modID.protein.faa \
              $ACCN.$HAP.modID.genes.gff3
  done

# Derive primary/longest CDS, transcript, and protein sequences
  for HAP in hap1 hap2; do
    cat $ACCN.$HAP.modID.transcripts.fna | longest_variant_from_fasta.sh > $ACCN.$HAP.modID.transcripts_primary.fna &
    cat $ACCN.$HAP.modID.CDS.fna | longest_variant_from_fasta.sh > $ACCN.$HAP.modID.CDS_primary.fna &
    cat $ACCN.$HAP.modID.protein.faa | longest_variant_from_fasta.sh > $ACCN.$HAP.modID.protein_primary.faa &
    wait
  done


# Compress the files
  for file in *gff3 *f?a *bed *.fasta; do 
    bgzip $file &
  done 

  rm *fai


#####
# Prepare the config for ds_souschef 

# NOTE difference in for handling an assembly and annotations with two haplotypes:
# It is best currently (Feb 2024) to make two config files -- one for hap1 and one for hap2, 
# because of the dependence in ds_souschef.pl on the strings genome_main and gene_models_main 
# in the config file and program.

# cd back to the main work directory
  cd $PRIVATE/$GENUS/$SP/$STRAIN.$GNM.$ANN
  vim $CONFIGDIR/$GENSP.$STRAIN.$GNM.$ANN.yml
  
  mkdir hap1 hap2

# Run ds_souschef.pl with the config above -- on TWO versions of the config -- one for each haplotype
  ds_souschef.pl -config $CONFIGDIR/$GENSP.$STRAIN.$GNM.${ANN}_hap1.yml
  mv annotations/ genomes/ hap1

  ds_souschef.pl -config $CONFIGDIR/$GENSP.$STRAIN.$GNM.${ANN}_hap2.yml
  mv annotations/ genomes/ hap2

# NOTE: Check the results for sanity.
# The fasta files (cds, transcript, protein) should all have prefixes (gensp.genotype.gnm#.ann#.)
  echo "Testing for hashing correctness. Counts of UNDEFINED should be 0 in all files."
  grep -c UNDEFINED annotations/$STRAIN.$GNM.$ANN.$AKEY/*

  
# Move the hap1 and hap2 files into common annotations/ and genomes/ directories, renaming the hap2 files

  mkdir -p annotations/$STRAIN.$GNM.$ANN.$AKEY
  mkdir -p genomes/$STRAIN.$GNM.$GKEY

  mv hap1/* .
  rm hap2/*/*/README*
  rm hap2/*/*/MANIFEST*
  rm hap2/*/*/CHANGES*

  mv hap2/genomes/$STRAIN.$GNM.$GKEY/$GENSP.$STRAIN.$GNM.$GKEY.genome_main.fna \
    genomes/$STRAIN.$GNM.$GKEY/$GENSP.$STRAIN.$GNM.${GKEY}_hap2.genome.fna

  rename.pl 's/([^.]+\.[^.]+\.[^.]+\.[^.]+)\./$1_hap2./' hap2/annotations/$STRAIN.$GNM.$ANN.$AKEY/*
  rename.pl 's/_main//' hap2/annotations/$STRAIN.$GNM.$ANN.$AKEY/*
  mv hap2/annotations/$STRAIN.$GNM.$ANN.$AKEY/*  annotations/$STRAIN.$GNM.$ANN.$AKEY/
  rm -rf hap2

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

