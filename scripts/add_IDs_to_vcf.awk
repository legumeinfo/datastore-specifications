#!/usr/bin/awk -f
#
# NAME
#   add_IDs_to_vcf.awk - add IDs to VCF file, in third column. Leave comment lines untouched.
# 
# SYNOPSIS
#   add_IDs_to_vcf.awk [INPUT_FILE]
#     
# OPERANDS
#     INPUT_FILE
#         A VCF file.
#     Also: set the DATASETID string in the BEGIN statement. 
#     Change the length of the zero-padding in the printf statement.
#

BEGIN { DATASET="A01."; ct=1; OFS="\t" }
/^#/ {print $0}
$1!~/^#/ {$3=sprintf("%s%07d", DATASET, ct); print $0; ct++}

