#!/usr/bin/env sh

# For fasta files (e.g. CDS, protein, mRNA) with splice variants of the form
#   >GENE_ID.1
# (variant signified by dot-separated digit at the end), 
# this script will return only the longest variant of each gene.

# Usage: cat $FILE.fa |  pick_longest_variant.sh

set -o errexit -o nounset

##################################################
# Functions (just to help document what's happening)

# Print fasta onto one line and report sequence length.
# NOTE: This discards the description if one is present.
fasta_to_table() {
  awk 'BEGIN { ORS="" }
       /^>/ && NR==1 { print substr($1,2) "\t" }
       /^>/ && NR!=1 { print "\n" substr($1,2) "\t" }
       /^[^>]/ { print }
       END { print "\n" }'
}

# Split gene splice_variant
split_gene_splicevar() {
  perl -pe 's/^(\S+)\.(\w*\d+)\t(\S+)/$1\t$2\t$3/' |
  awk -v OFS="\t" '{print $1, $2, length($3), $3}'
}

# Sort by geneID, then length (reverse numerically)
sort_by_length() {
  sort -k1,1 -k3nr,3nr
}

# Top line
top_line() {
  awk 'BEGIN { MAX = 1 }
       $1 == prev && count < MAX { print; count++ }
       $1 != prev { print; count = 1; prev = $1 }'
}

# Reassemble fasta
table_to_fasta() {
  awk -v OFS="" '{print ">" $1 "." $2 "\n" $4}' |
  fold -w100
}

##################################################
# Handle fasta sequence on stdin
fasta_to_table |
split_gene_splicevar |
sort_by_length |
top_line |
table_to_fasta


