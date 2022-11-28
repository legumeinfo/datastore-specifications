#!/usr/bin/env bash

set -o errexit
set -o nounset

script=`basename $0`

if [ $# -eq 0 ]; then
cat <<Usage-message
  Usage:    $script path_to_files_to_be_compressed

  This script compressses the data files and indexes them: 
  fasta files with "samtools faidx" and gff files with "tabix".
  Typical usage is to compress and files in a Data Store collection.s

  Examples:
    $script "."
    or 
    $script annotations/collection_name

Usage-message
fi

filepath=$1

for file in $filepath/*.txt; do
  if [[ $file =~ "readme" || $file =~ "usage" || $file =~ "olicy" || $file =~ "CHANGES" ]]; then
    echo "Don't compress file $file"
  else 
    echo "Compressing $file"
    bgzip -l9 $file &
  fi
done
wait

for file in $filepath/*.f?a $filepath/*.gff3 $filepath/*tsv; do
  if test -f $file; then
    echo "Compressing $file"
    bgzip -l9 $file &
  fi
done
wait

for file in $filepath/*.f?a.gz; do 
  if test -f $file; then
    echo "Indexing fasta files: $file"
    samtools faidx $file &
  fi
done
wait

for file in $filepath/*.gene_models_main.gff3.gz; do
  if test -f $file; then
    echo "Indexing GFF files: $file"
    tabix $file -f &
  fi
done
wait

echo "Done with compressing and indexing."

