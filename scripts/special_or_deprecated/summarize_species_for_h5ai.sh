#!/usr/bin/env bash

set -o errexit
set -o nounset

base="/usr/local/www/data/v2"
script=`basename $0`

if [ $# -eq 0 ]; then
cat <<Usage-message
  Usage:    $script Genus species

  Example: After adding one or more collections in Glycine/max (say, a genome and annotation),
  call the script to update the overviews for this species:
    $script Glycine max

  This will derive an html-format "overview" from README files in the 
  data collections within each data-type directory (genomes, annotations, etc.),
  for display in the _h5ai html browser view of the Data Store.
  Summaries are derived from the synopsis field in the READMEs, and are 
  written to _h5ai.header.html in the Data Store locations indicated species -
  for example, at the top of https://legumeinfo.org/data/v2/Glycine/max/genomes/
  and at the top of https://legumeinfo.org/data/v2/Glycine/max/annotations/, etc.

  The script needs to be run on the file system at $base

Usage-message
fi

genus=$1
species=$2

speciesdir="$base/$genus/$species"

for path in $speciesdir/*; do
  type=`basename $path`
  if [[ $type != "about_this_collection" && $type != "GENUS" ]]; then 
    HEADERFILE="$path/_h5ai.header.html"
    echo "<p><b><big>Overview of data in this directory</big></b></p>" > $HEADERFILE
    find $path -name "README*.yml" -print0 | sort -z | xargs -0 | 
      perl -pe 's/ /\n/g' | grep -v "\/\." | xargs -I{} grep -iH "synopsis:" {} |
      perl -pe 's{\S+/([^/]+)/READ.+synopsis:\s+(\S.+)}{  <b>$1:<\/b> $2<br>}i' | 
      perl -pe 's/"//g' >> $HEADERFILE
    echo "<hr>" >> $HEADERFILE
  fi
done

