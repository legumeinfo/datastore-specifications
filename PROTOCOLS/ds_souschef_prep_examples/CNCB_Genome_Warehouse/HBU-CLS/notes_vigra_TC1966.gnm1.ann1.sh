# Objective: prepare assembly for Data Store. File-prep started 2026-09-23
# run on ceres.scinet.usda.gov
# W.Huang

# See the document here for detailed (general) instructions:
#   https://github.com/legumeinfo/datastore-specifications/tree/main/PROTOCOLS

# Data from https://ngdc.cncb.ac.cn/gwh/Assembly/86096/show
#RefSeq assembly GWHFDOU00000000.1 TC1966_assembly

cat << DONT_RUN_ME
This file contains notes for creating genome and annotation collections for the Data Store. Read them critically,
revise for your particular job, and copy-paste in an interactive terminal session. The file has a suffix ".sh"
only to get syntax highlighting in an editor (e.g. vim). It should not be executied as a shell script.
DONT_RUN_ME
echo; exit 1;

<< REFERENCE
Honglin Chen, Longsheng Xing, Chaonan Guan, Yang Liu, Tianxiao Chen, Rong Cao, Qiannan Song, Rutwik Barmukh, Reyazul Rouf Mir, Liangliang Hu, Bin Zhou, Gaoling Luo, Dongxu Xu, Fengxiang Yin, Xingxing Yuan, Suhua Wang, Xin Chen, Lixia Wang, Chengzhi Jiao, Huilong Du, Meiliang Zhou, Rajeev K Varshney, Xuzhen Cheng. Graph-based pan-genome reveals structural variations associated with agronomic traits in mung bean, Nat Genet. 2026 Jul;58(7):1696-1710.  doi: 10.1038/s41588-026-02644-5.  Epub 2026 Jul 10.
REFERENCE

# NOTE: utility scripts are at /project/legume_project/datastore/datastore-specifications/scripts/
# If not added already to the PATH, do:
    PATH=/project/legume_project/datastore/datastore-specifications/scripts:$PATH 

# Variables for this job
  PRIVATE=/project/legume_project/datastore/private  # Set this to the Data Store private root directory, i.e. ...data/private
  ACCN=GWHFDOU00000000.1
  STRAIN=TC1966
  GENUS=Vigna
  SP=radiata
  GENSP=Vigra
  GNM=gnm1
  ANN=ann1  
  GENOME=GWHFDOU00000000.1.genome.fasta
  CONFIGDIR=/project/legume_project/datastore/datastore-specifications/scripts/ds_souschef_configs
  FROM=$ACCN
  TO=derived

# NOTE: Get the keys with register_key.pl below !
  GKEY=JCV1
  AKEY=7Q14

# Registe new keys at /project/legume_project/datastore/datastore-registry
# See notes notes_HBU-CLS_prep.sh for datastore-registry step

# NOTE: Remember to add, commit, and push the updated ds_registry.tsv  

# Make and cd into a work directory
  mkdir -p $PRIVATE/$GENUS/$SP/$STRAIN.$GNM.$ANN
  cd $PRIVTE/$GENUS/$SP/$STRAIN.$GNM.$ANN


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
	  perl -pe 's/^>(\S+)\s+Chromosome\s+(\d)\s+.+/>Chr0$2 $1/; s/^>(\S+)\s+Chromosome\s+(\d\d)\s+.+/>Chr$2 $1/;s/^>(\S+)\s+OriSeqID=(scaf.+)\s+.+/>$2 $1/' > $TO/$ACCN.modID.genome.fasta 

## sort Chromosome and scaf IDs in order in the genome fasta file (Chr1...Chr11...)
ml seqkit

fasta_to_zero_lines.awk $TO/$ACCN.modID.genome.fasta |sort |perl -pe 's/(.+\.\d)\s+/$1\n/' >$TO/sorted.fa   #The -V flag in the sort command stands for natural sort (also called version sort). 
seqkit seq -w 80 $TO/sorted.fa >wrap80.fasta  #wrap 80 characters per line.
mv $TO/wrap80.fasta $TO/$ACCN.modID.genome.fasta
rm $TO/sorted.fa 
 
# Also in the molecule IDs in the gff. 
  grep ">"  $FROM/$GENOME |
    perl -pe 's/^>(\S+)\s+Chromosome\s+(\d)\s+.+/$1 Chr0$2/; s/^>(\S+)\s+Chromosome\s+(\d\d)\s+.+/$1 Chr$2/; s/^>(\S+)\s+OriSeqID=(scaf.+)\s+.+/$1 $2/'> $TO/$ACCN.initial_seqid_map.tsv



# sort Chromosome and scaf IDs in order in the genome fasta file (Chr1...Chr11...)
#ml samtools seqkit
#samtools faidx $TO/$GENOME
#cut -f1 $TO/$GENOME.fai |sort -V > $TO/sorted_headers.txt #The -V flag in the sort command stands for natural sort (also called version sort).
#seqkit faidx $TO/$GENOME -l $TO/sorted_headers.txt -w 80  >$TO/genome_sorted.fa
#mv $TO/genome_sorted.fa $TO/$ACCN.modID.genome.fasta

# Simplify the GFF, replace GWH assembly Accesion number with its corresonding Chr and scaf name, and replace the gene name its ID name and mRNA is the geneName with .1.

  cd $PRIVATE/$GENUS/$SP/$STRAIN.$GNM.$ANN

  hash_into_gff_id.pl -gff $FROM/$ACCN.gff -seqid_map $TO/$ACCN.initial_seqid_map.tsv |
    perl -ne 'if (/^#/) {print} else {@line= split("\t", $_); if ($line[2] =~ /gene/ ) {$line[8]=~ s/ID=(.+);Acce.+/ID=$1;Name=$1/; $new_line=join("\t",  @line); print "$new_line" }
      elsif ($line[2] =~ /mRNA/) {$line[8] =~ s/ID=.+\|.+\|(.+)\.t1.+;Accession=\S+;(Parent=.+);Parent_.+/ID=$1.1;Name=$1.1;$2/; $new_line_m=join("\t",  @line); print "$new_line_m" }
      elsif ($line[2] =~ /exon/) {$line[8] =~ s/ID=.+\|.+\|(.+)\.t1_mrna\.(.+);Parent=.+/ID=$1.1.$2;Name=$1.1.$2;Parent=$1.1/; $new_line_e=join("\t",  @line); print "$new_line_e" }
     elsif ($line[2] =~ /CDS/) {$line[8] =~ s/ID=.+\|.+\|(.+)\.t1.+(CDS\d+);Parent=.+/ID=$1.1.$2;Name=$1.1.$2;Parent=$1.1/; $new_line_d=join("\t",  @line); print "$new_line_d" } 
      elsif ($line[2] =~ /UTR/) {$line[8] =~ s/ID=.+\|.+\|(.+)\.t1_mrna\.(.+);Parent=.+/ID=$1.1.$2;Name=$1.1.$2;Parent=$1.1/; $new_line_u=join("\t",  @line); print "$new_line_u"}}' > tmp.modID.simplified.gff 


# Sort GFF 
cat tmp.modID.simplified.gff | sort_gff.pl > $TO/$ACCN.modID.genes_exons.gff3


# Remaining work in the work directory is in the "$TO" subdirectory
  cd $TO  
# to use gffread
ml miniconda
source activate /project/legume_project/datastore/conda-envs/ds-curate

# Extract CDS, mRNA, and protein sequence. 
  gffread -g $ACCN.modID.genome.fasta \
          -w $ACCN.modID.transcripts.fna -x $ACCN.modID.CDS.fna -y $ACCN.modID.protein.faa \
             $ACCN.modID.genes_exons.gff3

# Derive bed file
  cat $ACCN.modID.genes_exons.gff3 | gff_to_bed7_mRNA.awk | sort -k1,1 -k2n,2n > $ACCN.modID.bed

# Derive primary/longest CDS, transmodID.genes_exons.gff3cript, and protein sequences
  cat $ACCN.modID.transcripts.fna | longest_variant_from_fasta.sh > $ACCN.modID.transcripts_primary.fna &

# Compress the files
  for file in *gff3 *f?a *bed *.fasta; do 
    bgzip -l9 $file &
  done 
  wait

  rm *fai

# cd back to the main work directory
  cd $PRIVATE/$GENUS/$SP/$STRAIN.$GNM.$ANN

# Prepare the config for ds_souschef, in the datastore-specifications/scripts/ds_souschef_configs directory
  vim $CONFIGDIR/$GENSP.$STRAIN.$GNM.$ANN.yml

# Run ds_souschef.pl with the config above
  ds_souschef.pl -config $CONFIGDIR/$GENSP.$STRAIN.$GNM.$ANN.yml
# check the genome fasta defline, and sorted them by chromosome num

# NOTE: Check the results for sanity.
# The fasta files (cds, transcript, protein) should all have prefixes (gensp.genotype.gnm#.ann#.)
  cd $PRIVATE/$GENUS/$SP/$STRAIN.$GNM.$ANN

  echo "Testing for hashing correctness. Counts of UNDEFINED should be 0 in all files."
  grep -c UNDEFINED annotations/$STRAIN.$GNM.$ANN.$AKEY/*


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


