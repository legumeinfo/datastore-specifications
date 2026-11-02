# Objective: prepare assembly for Data Store. File-prep started 2026-10-19
# run on ceres.scinet.usda.gov
# W.Huang

# See the document here for detailed (general) instructions:
#   https://github.com/legumeinfo/datastore-specifications/tree/main/PROTOCOLS

# Data from https://cgm.sjtu.edu.cn/PeanutPan/index.html


cat << DONT_RUN_ME
This file contains notes for creating genome and annotation collections for the Data Store. Read them critically,
revise for your particular job, and copy-paste in an interactive terminal session. The file has a suffix ".sh"
only to get syntax highlighting in an editor (e.g. vim). It should not be executied as a shell script.
DONT_RUN_ME
echo; exit 1;

<< REFERENCE
Kunkun Zhao, Hongzhang Xue, Guowei Li, Annapurna Chitikineni, Yi Fan, Zenghui Cao, Xiaorui Dong, Huimin Lu, Kai Zhao, Lin Zhang, Ding Qiu, Rui Ren, Fangping Gong, Zhongfeng Li, Xingli Ma, Shubo Wan, Rajeev K. Varshney, Chaochun Wei & Dongmei Yin. Pangenome analysis reveals structural variation associated with seed size and weight traits in peanut. Nature Genetics 2025 Apr. 28. doi: 10.1038/s41588-025-02170-w
REFERENCE

module load miniconda
source activate /project/legume_project/datastore/conda-envs/ds-curate

# NOTE: utility scripts are at /project/legume_project/datastore/datastore-specifications/scripts/
# If not added already to the PATH, do:
  PATH=/project/legume_project/datastore/datastore-specifications/scripts:$PATH

# This collection is one of six described in Zhao_Xue_2025: one for duranensis two for monticola, and four for hypogaea.
# Do the preparation work for all three species in the pangene collection at
# /project/legume_project/datastore/private/Arachis/Zhao_Xue_2025_pan
  PAN_GROUP=Zhao_Xue_2025_pan

# Variables for this job
  PRIVATE=/project/legume_project/datastore/private  # Set this to the Data Store private root directory, i.e. ...data/private
  STRAIN=H16_5
  GENUS=Arachis 
  SP=monticola
  GENSP=H16_5
  GNM=gnm1
  ANN=ann1
  GENOME=H16_5.fna
  CONFIGDIR=/project/legume_project/datastore/datastore-specifications/scripts/ds_souschef_configs
  FROM=original
  TO=derived
# NOTE: Get the keys with register_key.pl below !
  GKEY=W31Y
  AKEY=ZYHW

# Register new keys at peanutbase-stage:/project/legume_project/datastore/datastore-registry
# NOTE: Remember to fetch and pull before generating new keys.
  cd /project/legume_project/datastore/datastore-registry
  ./register_key.pl -v "$GENUS $SP genomes $STRAIN.$GNM"
  ./register_key.pl -v "$GENUS $SP annotations $STRAIN.$GNM.$ANN"

# Make and cd into a work directory
 mkdir $FROM 
 mkdir -p $PRIVATE/$GENUS/$PAN_GROUP/$STRAIN.$GNM.$ANN
  cd $PRIVATE/$GENUS/$PAN_GROUP/$STRAIN.$GNM.$ANN
 mkdir $TO 
# Get the genome assembly and annotations
#  download data from 
#
  cd ../$FROM
  curl -O https://cgm.sjtu.edu.cn/PeanutPan/data/Genome/H16_5.fa.gz
  curl -O https://cgm.sjtu.edu.cn/PeanutPan/data/Genome/H16_5.gff3.gz 
  #Uncompress the data 
  gunzip *
  #original genome fasta sequences is wrapped 100 per line
  
  cp $STRAIN.fna > ../$TO/$STRAIN.fasta

# Prepare the data here:
  cd $PRIVATE/$GENUS/$PAN_GROUP/$STRAIN.$GNM.$ANN

cat $FROM/$STRAIN.gff3 |
 perl -ne '@line= split("\t", $_); if ($line[2] =~ /gene/) {$line[8] =~ s/ID=(.+);/ID=$1;Name=$1/; $new_line_g=join("\t",  @line); print "$new_line_g" }
    elsif ($line[2] =~ /mRNA/) {$line[8] =~ s/ID=(.+);(Parent=.+);Function.+/ID=$1;$2;Name=$1/; $new_line_m=join("\t",  @line); print "$new_line_m" }
    else {$line[8] =~ s/ID=.+\.(\S+);Parent=(.+);/ID=$2.$1;Parent=$2;Name=$2.$1/; $new_line=join("\t",  @line); print "$new_line"}' |
      sort_gff.pl > $TO/tmp.simplified.gff3

# Use gffread to derive protein, CDS, and transcript files; then separate GFF into coding and noncoding
# based on list of protein-coding genes.

  cd $TO
 
  gffread -g $FROM/$STRAIN.fasta \
          -w $STRAIN.transcript.fna \
          -x $STRAIN.CDS.fna \
          -y $STRAIN.protein.faa \
             $TO/$STRAIN.mod.gff

# Derive bed file
  cat $TO/$STRAIN.mod.gff | gff_to_bed7_mRNA.awk | sort -k1,1 -k2n,2n > $TO/$STRAIN.mod.bed

# get longest CDS, protein and transcript
cat $TO/$STRAIN.CDS.fna | longest_variant_from_fasta.sh > $TO/$STRAIN.CDS_primary.fna
cat $TO/$STRAIN.protein.faa | longest_variant_from_fasta.sh >$TO/$STRAIN.protein_primary.faa
cat $TO/$STRAIN.transcript.fna | longest_variant_from_fasta.sh >$TO/$STRAIN.transcript_primary.fna

# Compress the files
  cd derived

  for file in *gff *f?a *bed *fasta; do
    bgzip -l9 $file &
  done
  wait

  rm *fai

# Split gff into coding and noncoding genes

# cd back to the main work directory
  cd $PRIVATE/$GENUS/$PAN_GROUP/$STRAIN.$GNM.$ANN

# Prepare the config for ds_souschef, in the datastore-specifications/scripts/ds_souschef_configs directory
  vim $CONFIGDIR/$PAN_GROUP/$GENSP.$STRAIN.$GNM.$ANN.yml

# Run ds_souschef.pl with the config above
  ds_souschef.pl -config $CONFIGDIR/$PAN_GROUP/$GENSP.$STRAIN.$GNM.$ANN.yml

# NOTE: Check the results for sanity.
# The fasta files (cds, transcript, protein) should all have prefixes (gensp.genotype.gnm#.ann#.)
  cd $PRIVATE/$GENUS/$PAN_GROUP/$STRAIN.$GNM.$ANN

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
