#!/usr/bin/env sh
# Calculate chromosome-GFF from fasta sequence.
# Derived from load_reference.sh, which loads the output into a SQLite database for gbrowse.
set -o errexit -o nounset

# parameters
GENOME=$1       # genome FASTA file
GFF3_SOURCE=$2  # for fasta column 2, e.g. "glyma.Lee.gnm1"

: "${2:?} ${1:?}"

# print seqid length
seqlen() {
  awk '/^>/ {if (len) print len; len = 0; printf("%s\t", substr($1,2)); next}
       { len+=length }
       END {if (len) print len}' $GENOME
}

{
  printf '##gff-version 3\n'   

  seqlen "$GENOME" |
    while read -r seqid length
    do
      # e.g., Vu01 is a chromosome; cicar.scaffold2491 is a scaffold;
      # contig66689 is a contig
      case ${seqid} in
        ara*) type=chromosome;;
        Chr*) type=chromosome;;
        chr*) type=chromosome;;
        Gm*) type=chromosome;;
        Gs*) type=chromosome;;
        *sc*) type=scaffold ;;
        *cont*) type=contig ;;
        Tig*) type=contig ;;
        tig*) type=contig ;;
      esac
      
      printf '%s\t%s\t%s\t1\t%u\t.\t.\t.\tName=%s\n' \
             ${seqid} ${GFF3_SOURCE} ${type} ${length} ${seqid}
    done
} 

