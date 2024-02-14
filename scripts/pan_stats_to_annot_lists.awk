#!/usr/bin/awk -f
#
# NAME
#   pan_stats_to_annot_lists.awk - From a pandagma stats.txt file, extract lists of
#     accessions used in the pangene set: one list of annotations_main and one of annotations_extra.
#     This information is used in those two fields in the pangene README files.
#  
# SYNOPSIS
#   cat stats.txt | pan_stats_to_annot_lists.awk
#     
# OPERANDS
#     INPUT_FILE
#         A stats.txt file generated as part of the pandagma pan workflow. 
#         The key section is == Sequence stats for CDS files, which gives stats for annotations
#         in two groups: "Main:" and "Extra".

BEGIN { OFS = "" }

seen_main > 0  && $1~/Main:/ {main = main ", " $7 } 
seen_extra > 0 && $1~/Extra:/ {extra = extra ", " $7 } 

seen_main == 0  && $1~/Main:/ {main = $7; seen_main++ } 
seen_extra == 0 && $1~/Extra:/ {extra = $7; seen_extra++ } 

END{ print "\n    annotations_main: " main "\n"; print "    annotations_extra: " extra "\n" }

