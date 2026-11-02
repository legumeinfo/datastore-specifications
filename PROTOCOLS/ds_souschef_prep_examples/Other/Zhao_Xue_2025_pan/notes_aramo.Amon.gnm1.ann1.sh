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
  STRAIN=Amon
  GENUS=Arachis 
  SP=monticola
  GENSP=aramo
  GNM=gnm1
  ANN=ann1
  GENOME=Amon.fna
  CONFIGDIR=/project/legume_project/datastore/datastore-specifications/scripts/ds_souschef_configs
  FROM=original
  TO=derived
# NOTE: Get the keys with register_key.pl below !
  GKEY=6MP7
  AKEY=J36L

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
  curl -O https://cgm.sjtu.edu.cn/PeanutPan/data/Genome/Amon.fa.gz
  curl -O https://cgm.sjtu.edu.cn/PeanutPan/data/Genome/Amon.gff3.gz 
  #Uncompress the data 
  gunzip *
  #original genome fasta sequences is wrapped 100 per line

  cd $PRIVATE/$GENUS/$PAN_GROUP/$STRAIN.$GNM.$ANN

# Copy over the genome file. Change chromosome names from A01..A10,B01..B10 to Chr01..Chr20
  cat ../$FROM/Amon.fna | sed -e 's/^>A/>Chr/' | sed -e 's/^>B0/>Chr1/' | sed 's/>B10/>Chr20/' > $TO/Amon.fasta

# Also change chromosome names from A01..A10,B01..B10 to Chr01..Chr20
 cat ../$FROM/Amon.gff3 | simplify_genbank_gff.sh |
   perl -ne '@line= split("\t", $_); if ($line[2] =~ /mRNA/) {$line[8] =~ s/ID=(.+)\.mRNA;(Parent=.+);Name=.+/ID=$1.1;$2;Name=$1.1/; $new_line_m=join("\t",  @line); print "$new_line_m" }
      elsif ($line[2] =~ /exon/ && $line[1] =~ /./) {$line[8] =~ s/ID=exon-(.+)\.mRNA\.(.+);Parent=.+/ID=$1.1.$2;Parent=$1.1;Name=$1.1.$2/; $new_line_e1=join("\t",  @line); print "$new_line_e1" }
      elsif ($line[2] =~ /CDS/ && $line[1] =~ /./) {$line[8] =~ s/ID=(cds)\.(.+)\.mRNA-(.+);Parent=.+/ID=$2.1.$1$3;Parent=$2.1;Name=$2.1.$1$3/; $new_line_d1=join("\t",  @line); print "$new_line_d1" }
      elsif ($line[2] =~ /UTR/) {$line[8] =~ s/ID=(.+)\.mRNA\.(.+);Parent=.+/ID=$1.1.$2;Parent=$1.1;Name=$1.1.$2/; $new_line_u=join("\t",  @line); print "$new_line_u"}
      else {$new_line =join("\t",  @line); {print "$new_line"}}' | 
        perl -pe 's/exon-//gc; s/\.mRNA/.1/; s/\.(cds\d+)-1/.1.$1/g' |
        sed -e 's/^A/Chr/' | sed -e 's/^B0/Chr1/' | sed 's/B10/Chr20/' | 
        sort_gff.pl > $TO/Amon.mod.gff

# Use gffread to derive protein, CDS, and transcript files; then separate GFF into coding and noncoding
# based on list of protein-coding genes.

  cd $TO
 
  gffread -g $STRAIN.fasta \
          -w $STRAIN.transcript.fna \
          -x $STRAIN.CDS.fna \
          -y $STRAIN.protein.faa \
             $STRAIN.mod.gff

# Derive bed file
  cat $STRAIN.mod.gff | gff_to_bed7_mRNA.awk | sort -k1,1 -k2n,2n > $STRAIN.mod.bed

# Derive primary/longest CDS, transcript, and protein sequences
  cat $STRAIN.CDS.fna | longest_variant_from_fasta.sh > $STRAIN.CDS_primary.fna
  cat $STRAIN.protein.faa | longest_variant_from_fasta.sh > $STRAIN.protein_primary.faa
  cat $STRAIN.transcript.fna | longest_variant_from_fasta.sh > $STRAIN.transcript_primary.fna

# Compress the files

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
