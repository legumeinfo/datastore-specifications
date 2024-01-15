#!/usr/bin/env sh

if test -t 0; then
cat <<Usage-message
  Usage: cat genomic.gff | simplify_genbank_gff.sh

  Simplify GenBank GFF files, reducing the 9th column to contain only ID attributes for gene records
  and only ID and Parent attributes for sub-features of genes (CDS, mRNA, UTRs). Remove Note, Name, etc.
  Also, for CDS features, replace with name of parent, and number the features to produce unique IDs.
  Finally, generate Name using the same value as the ID.

  May be used with hash_into_gff_id.pl and a hash file of gene IDs and/or seqids.

  Lightly tested. Modification will probably be needed to handle other GenBank GFF forms.

Usage-message
exit
fi

perl -pe 's/\|WGS:\w+//g; s/\w+-gnl\|//g; s/;(Note=|gbkey=|Dbxref=|Name=).+//' | # Simplify 9th col to ID or ID+Parent
  perl -pe 's/rna-//g; s/gene-//g; s/exon-//g' | # Strip feature types from IDs except cds
  perl -pe 's/ID=(cds-[^;]+);Parent=(.+)/ID=$2;Parent=$2/' |  # For CDS features, replace with name of parent
  perl -pe 's/;/\t/g' |  # Temporarily split 9th column on semicolons
  awk -v OFS="\t" '$3 ~ /CDS/ && $9 != prev {ct=1; print $1, $2, $3, $4, $5, $6, $7, $8, $9 "-" ct, $10; prev=$9; next}
                   $3 ~ /CDS/ && $9 == prev {ct++; print $1, $2, $3, $4, $5, $6, $7, $8, $9 "-" ct, $10; prev=$9}
                   $3 !~ /CDS/ {print}' |
  awk -v OFS="\t" '$3 ~ /exon/ {ID_val = substr($9,4); print $1, $2, $3, $4, $5, $6, $7, $8, "ID=exon-" ID_val, $10}
                   $3 !~ /exon/ {print}' |
  perl -pe 's/ID=(\S+)$/ID=$1;Name=$1/; s/ID=(\S+)\tParent=(\S+)/ID=$1;Parent=$2;Name=$1/'


##########
# Versions
# 2023-07-05 First version. 
# 2023-07-08 Fix bug in naming of exon features
