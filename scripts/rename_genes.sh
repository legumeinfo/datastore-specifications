#!/usr/bin/env sh

if test -t 0; then
cat <<Usage-message
  Usage: cat FILE.gff3 | rename_genes.sh [gene_prefix_string]

  For a GFF file with gene IDs of the form "g1" and sub-feature IDs of the form "g1.t1", "g1.t1.CDS1", etc.
  (as generated by BRAKER3), generate a hash file with new IDs in the second column, e.g.
      g1	ApiamH1.Chr01G000100
      g1.t1	ApiamH1.01G000100.t1
      g1.t1.start1	ApiamH1.01G000100.t1.start1

  The value in the positional argument is a prefix to be used in the new IDs. In the example above:
    cat braker.gff3 | rename_genes.sh ApiamH1
Usage-message
exit
fi

set -o errexit -o nounset

if [[ $# -eq 0 ]]; then
  echo
  echo "Please provide a string to be used as the prefix for the gene IDs, for example \"GenspH1\""
  echo
  exit 1;
else
  PREFIX=$1;
fi 

##################################################
# Functions (just to help document what's happening)

##########
# Sample input:
#   Chr01	AUGUSTUS	gene	57193	58107	.	+	.	ID=g1;
#   Chr01	AUGUSTUS	mRNA	57193	58107	1	+	.	ID=g1.t1;Parent=g1;
#
# Sample output: 
#   01	1
#   01	1	t1
#   01	1	t1.start1

split_gff_to_parts() {
  perl -lane 'if ($F[2]=~/gene/) {
                $chr=$F[0];
                $ID=$F[8];
                $chr=~s/^\D+(\d+)/$1/;
                $ID=~s/ID=g(\d+);/$1/;
                print join("\t", $chr, $ID);
              }
              else {
                 $chr=$F[0];
                 $ID=$F[8];
                 $chr=~s/^\D+(\d+)/$1/;
                 $ID=~s/ID=g(\d+)\.([^;]+);.+/$1\t$2/;
                 print join("\t",$chr, $ID);
              }'
}

##########
# Assuming features are ordered by chromosome and then positionally within the chromosome,
# generate a new column of numbers that increment on each chromosome, beginning from 1 at the chromosome start.

# Sample output:
#   1	01	1
#   1	01	1	t1
#   1	01	1	t1.start1
#   ...
#  1582	11	25667	t1.exon1
#  1582	11	25667	t1.start1

make_gene_numbers_by_chr() {
  awk -v OFS="\t" '$1!=prev_chr { print 1, $0; prev_chr=$1; prev_ct=$2; ct=1; next }
                   $1==prev_chr && $2!=prev_ct { ct++; print ct, $0; prev_chr=$1; prev_ct=$2; next }
                   $1==prev_chr && $2==prev_ct {       print ct, $0; prev_chr=$1; prev_ct=$2; next }
                  '
}

##########
# Print two-column results

# Sample output (given positional argument of ""ApiamH1):

#   g1	ApiamH1.01G000100
#   g1.t1	ApiamH1.01G000100.t1
#   g1.t1.start1	ApiamH1.01G000100.t1.start1

sort_by_length() {
  awk -v PRE=$PREFIX 'NF==3 {printf("%s%s\t%s.%s%s%04d00\n", "g", $3, PRE, $2, "G", $1)}
                      NF==4 {printf("%s%s.%s\t%s.%s%s%04d00.%s\n", "g", $3, $4, PRE, $2, "G", $1, $4)}'
}

##################################################
# Handle fasta sequence on stdin
split_gff_to_parts |
make_gene_numbers_by_chr |
sort_by_length


##########
# Versions
# 2025-04-08 SCannon Initial version
