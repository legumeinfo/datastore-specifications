# Objective: prepare assembly for Data Store. File-prep started 2025-01-07
# S. Cannon

# See the document here for detailed (general) instructions:
#   https://github.com/legumeinfo/datastore-specifications/tree/main/PROTOCOLS

# Data from genome assemblies and annotations from the National Agriculture and Food Research Organization (NARO; Japan)
# This set comprises 11 assemblies and annotations. The assemblies are at 
#   https://www.ncbi.nlm.nih.gov/bioproject/PRJNA1198394
# The annotations are at
#   https://daizu-net.dna.affrc.go.jp/ap/dnl

# NOTE: These notes are different than the other single-accession notes in that they are structured for preparing
# all eleven assemblies and annotations in a batch.

cat << DONT_RUN_ME
This file contains notes for creating genome and annotation collections for the Data Store. Read them critically,
revise for your particular job, and copy-paste in an interactive terminal session. The file has a suffix ".sh"
only to get syntax highlighting in an editor (e.g. vim). It should not be executied as a shell script.
DONT_RUN_ME
echo; exit 1;

<< REFERENCE
submitted by National Agriculture and Food Research Organization (NARO); no reference yet
REFERENCE

# NOTE: utility scripts are on ceres at /project/legume_project/datastore/datastore-specifications/scripts
# If not added already to the PATH, do:
    PATH=/project/legume_project/datastore/datastore-specifications/scripts:$PATH 

# Additional setup if necessary (one-time installation of gffread as a conda package)
  salloc -N 1 -n 36 -t 2:00:00 -p short

  ml miniconda

  source activate ds-curate
    # See notes for installing several packages into the "ds-curate" conda environment at
    # https://github.com/legumeinfo/datastore-specifications/blob/main/PROTOCOLS/ds_souschef_prep_examples/README.md

# Variables for this job
  PRIVATE=/project/legume_project/datastore/private  # Set this to the Data Store private root directory, i.e. ...data/private
  GENUS=Glycine
  SP=max
  GENSP=glyma
  GNM=gnm3
  ANN=ann1  
  CONFIGDIR=/project/legume_project/datastore/datastore-specifications/scripts/ds_souschef_configs/NARO_collection
  TO=derived

# Per-assembly variables, set in shell loops below
#  ACCN=GCA_046254585.1
#  STRAIN=Harosoy
#  GKEY=TKJB
#  AKEY=R35Y
#  FROM=$ACCN

cat << IDs_and_versions
Assembly	BioSample	Cultivar              ncbi ver    Daizu-net ver
GCA_046254585.1	SAMN45842306	Harosoy       v3.01
GCA_046254595.1	SAMN45842307	UA4805        v3.01
GCA_046254555.1	SAMN45842308	Peking        v3.01
GCA_046254605.1	SAMN45842305	Jack          v3.01
GCA_046254675.1	SAMN45842303	Ooyachi2      v3.03
GCA_046254615.1	SAMN45842304	Tanba         v3.02
GCA_046254695.1	SAMN45842302	Miyagishirome v3.01
GCA_046254705.1	SAMN45842300	Himeshirazu   v3.02
GCA_046254725.1	SAMN45842299	Fukuyutaka    v3.12
GCA_046254735.1	SAMN45842298	Enrei         v3.31     v3.32; annot change only
GCA_046254715.1	SAMN45842301	Kosuzu        v3.01
IDs_and_versions


# Make and cd into a work directory
#  NOTE: For the collection of 11 genomes from NARO, we use an extra project subdirectory of that name
  mkdir -p $PRIVATE/$GENUS/$SP/NARO/
  cd $PRIVATE/$GENUS/$SP/NARO/

# Make a list of STRAIN names and accessions
cat <<STRAINS_ACCNS > lis.to_process
Harosoy  GCA_046254585.1
UA4805  GCA_046254595.1
Peking  GCA_046254555.1
Jack  GCA_046254605.1
Ooyachi2  GCA_046254675.1
Tanba  GCA_046254615.1
Miyagishirome  GCA_046254695.1
Himeshirazu  GCA_046254705.1
Fukuyutaka  GCA_046254725.1
Enrei  GCA_046254735.1
Kosuzu  GCA_046254715.1
STRAINS_ACCNS

perl -pi -e 's/ +/\t/' lis.to_process


  cd /project/legume_project/datastore/datastore-registry

  GENUS=Glycine
  SP=max
  GNM=gnm3
  ANN=ann1

  cat /project/legume_project/datastore/private/Glycine/max/NARO/lis.to_process | awk '{print $1}' |
    while read -r STRAIN; do
      echo $STRAIN
      ./register_key.pl -v "$GENUS $SP genomes $STRAIN.$GNM"
      ./register_key.pl -v "$GENUS $SP annotations $STRAIN.$GNM.$ANN"
    done

      TKJB  Glycine max genomes Harosoy.gnm3
      R35Y  Glycine max annotations Harosoy.gnm3.ann1
      THQ0  Glycine max genomes UA4805.gnm3
      DTQV  Glycine max annotations UA4805.gnm3.ann1
      KKCD  Glycine max genomes Peking.gnm3
      D1WG  Glycine max annotations Peking.gnm3.ann1
      05MK  Glycine max genomes Jack.gnm3
      S50K  Glycine max annotations Jack.gnm3.ann1
      3469  Glycine max genomes Ooyachi2.gnm3
      6929  Glycine max annotations Ooyachi2.gnm3.ann1
      4HTT  Glycine max genomes Tanba.gnm3
      17JT  Glycine max annotations Tanba.gnm3.ann1
      5Z0W  Glycine max genomes Miyagishirome.gnm3
      P8QZ  Glycine max annotations Miyagishirome.gnm3.ann1
      61YZ  Glycine max genomes Himeshirazu.gnm3
      0KJD  Glycine max annotations Himeshirazu.gnm3.ann1
      424H  Glycine max genomes Fukuyutaka.gnm3
      RWJM  Glycine max annotations Fukuyutaka.gnm3.ann1
      MF2C  Glycine max genomes Enrei.gnm3
      YRG3  Glycine max annotations Enrei.gnm3.ann1
      9GPW  Glycine max genomes Kosuzu.gnm3
      4MVB  Glycine max annotations Kosuzu.gnm3.ann1



# Make subdirectories and get data from GenBank
  base_dir=/project/legume_project/datastore/private/Glycine/max/NARO
  
  cat lis.to_process | while read -r line; do
    STRAIN=$(echo $line | awk '{print $1}');
    ACCN=$(echo $line | awk '{print $2}');
    echo $STRAIN, $ACCN;
    mkdir -p $STRAIN.gnm3.ann1
    cd $STRAIN.gnm3.ann1
      datasets download genome accession $ACCN --include gff3,rna,cds,protein,genome,seq-report
      unzip ncbi_dataset.zip
      mv ncbi_dataset/data/* .
      mv assembly_data_report.jsonl dataset_catalog.json GC*/
      rm -rf ncbi_dataset/ ncbi_dataset.zip
      rm README.md md5sum.txt
    cd $base_dir
  done


# Start an interactive session and load gffread using conda
  salloc -N 1 -n 36 -t 2:00:00 -p short
  wait

  ml miniconda

  source activate gffread


# Swap the chromosome/seq IDs and the ACCN IDs in the assembly, from e.g.
#   >CM101201.1 Glycine max cultivar Harosoy chromosome 1, whole genome shotgun sequence
# to  (Note: the annotation and assembly files from NARO use lowercase "chr", so we will use that here)
#   >chr01 CM101201.1    

  base_dir=/project/legume_project/datastore/private/Glycine/max/NARO
  TO=derived

  cat lis.to_process | while read -r line; do
    STRAIN=$(echo $line | awk '{print $1}');
    ACCN=$(echo $line | awk '{print $2}');
    echo $STRAIN, $ACCN;

    cd $base_dir/$STRAIN.gnm3.ann1

    mkdir -p $TO

    # Swap the chromosome/seq IDs and the ACCN IDs in the assembly
      cat $ACCN/GCA*genomic.fna |
        perl -pe 's/^>(\S+)\s+.+chromosome (\d), .+/>chr0$2 $1/;
                  s/^>(\S+)\s+.+chromosome (\d\d), .+/>chr$2 $1/;
                  s/^>(\S+)\s+.+(Scaffold_\d+),.+/>$2 $1/' > $TO/$ACCN.modID.genome.fasta

    # Separate features on chromosomes and scaffolds
    # Simplify the molecule IDs in the gff, reducing from e.g. Harosoy301_chr01 to chr01
      cat Gmax_*.gff3 | awk '$1!~/scaff/' | perl -pe 's/^\w+_(chr\d\d)/$1/' |
        perl -pe 's/transcript/mRNA/' | sort_gff.pl > $TO/$ACCN.modID.genes_exons.gff3

      cat Gmax_*.gff3 | awk '$1~/^#/ || $1~/scaff/' | sort_gff.pl > $TO/$ACCN.scaffolds.gff3

    # Extract CDS, mRNA, and protein sequence; then derive bed file and longest seq representatives
      cd $TO  

        gffread -C -g $ACCN.modID.genome.fasta \
                   -w $ACCN.modID.transcripts.fna -x $ACCN.modID.CDS.fna -y $ACCN.modID.protein.faa \
                      $ACCN.modID.genes_exons.gff3

      # Derive bed file
        cat $ACCN.modID.genes_exons.gff3 | gff_to_bed7_mRNA.awk | sort -k1,1 -k2n,2n > $ACCN.modID.bed

      # Derive primary/longest CDS, transcript, and protein sequences
        cat $ACCN.modID.transcripts.fna | longest_variant_from_fasta.sh > $ACCN.modID.transcripts_primary.fna
        cat $ACCN.modID.CDS.fna | longest_variant_from_fasta.sh > $ACCN.modID.CDS_primary.fna
        cat $ACCN.modID.protein.faa | longest_variant_from_fasta.sh > $ACCN.modID.protein_primary.faa

    cd $base_dir
  done


# Compress the files
  cd $base_dir
  cat lis.to_process | while read -r line; do
    STRAIN=$(echo $line | awk '{print $1}');
    ACCN=$(echo $line | awk '{print $2}');
    echo $STRAIN, $ACCN;

    cd $base_dir/$STRAIN.gnm3.ann1/$TO

    for file in *gff3 *f?a *bed *.fasta; do 
      gzip $file &
    done 
    wait

    rm *fai
    cd $base_dir
  done

# cd back to the main work directory
  cd $PRIVATE/$GENUS/$SP/NARO/$STRAIN.$GNM.$ANN

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


