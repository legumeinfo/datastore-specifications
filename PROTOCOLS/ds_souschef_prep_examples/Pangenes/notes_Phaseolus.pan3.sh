# Objective: Prepare a pangene collection for the Data Store

# See the document here for detailed (general) instructions:
#   https://github.com/legumeinfo/datastore-specifications/tree/main/PROTOCOLS/README.md

cat << DONT_RUN_ME
This file contains notes for creating pangene collections for the Data Store. Read them critically, revise 
for your particular job, and copy-paste in an interactive terminal session. The file has a suffix ".sh" only 
 to get syntax highlighting in an editor (e.g. vim). It should not be executied as a shell script.
DONT_RUN_ME
echo; exit 1;

# Variables for this job
  PRIVATE=/project/legume_project/datastore/private  
  PUBLIC=/project/legume_project/datastore/v2 
  ANNEX=/project/legume_project/datastore/annex
  CONFIGDIR=/project/legume_project/datastore/datastore-specifications/scripts/ds_souschef_configs/pangene_sets

  GENUS=Phaseolus
  PANNUM=pan3

  KEY4=LXKV   # NOTE: Get the key with register_key.pl below !

# Register key. 
  cd /project/legume_project/datastore/datastore-registry
  ./register_key.pl -v "$GENUS GENUS pangenes $GENUS.$PANNUM"
  # Remember to add, commit, and push the updated ds_registry.tsv 
  
# Copy out_ directory from ceres to /project/legume_project/datastore/private/$GENUS/GENUS
  cd $PRIVATE/$GENUS/GENUS

# Prepare config - step 1. To get the annotation lists for annotations_main and annotations_extra, run the following
# (the script is in /project/legume_project/datastore/datastore-specifications/scripts):
  pan_stats_to_annot_lists.awk $PRIVATE/$GENUS/GENUS/out_pandagma/stats.txt

# Prepare the config - step 2. This is best done by copying from a previous config file and modifying fields as needed.
  vim $CONFIGDIR/$GENUS.$PANNUM.yml

# Run ds_souschef.pl
  ds_souschef.pl -conf $CONFIGDIR/$GENUS.$PANNUM.yml

# NOTE: Check the results for sanity.
# The fasta files (cds, transcript, protein) should all have prefixes (gensp.genotype.gnm#.ann#.)
  echo "Testing for hashing correctness. Counts of UNDEFINED should be 0 in all files."
  grep -c UNDEFINED annotations/$STRAIN.$GNM.$ANN.$AKEY/*

# Move files in collection directory into place in the ANNEX data store
  mkdir $ANNEX/$GENUS/GENUS/pangenes/$GENUS.$PANNUM.$KEY4
  mv $PRIVATE/$GENUS/GENUS/pangenes/$GENUS.$PANNUM.$KEY4/* \
       $ANNEX/$GENUS/GENUS/pangenes/$GENUS.$PANNUM.$KEY4/

# Compress and index
  compress_and_index.sh $ANNEX/$GENUS/GENUS/pangenes/$GENUS.$PANNUM.$KEY4


