# CHANGES file

A directory may contain a CHANGES.*collection*.txt file which lists file transformations and changes. For example:

```
file transformations:

seqlen.awk vigan.Gyeongwon.a3.v1.cds.fa | perl -pe 's/(\w+\.\w+)\.(\d+) (\d+)/$1\t$2\t$3/' | sort -k1,1 -k3nr,3nr | top_line.awk | awk '{print ">" $1 "." $2}' | sort > tmp.longest"

fasta_to_zero_lines.awk vigan.Gyeongwon.a3.v1.cds.fa | sort > tmp.fa.1ln

join tmp.longest tmp.fa.1ln | perl -pe 's/ zqz /\n/' > vigan.Gyeongwon.gnm3.ann1.3Nz5c.cds_primaryTranscript.fna

seqlen.awk vigan.Gyeongwon.a3.v1.peptide.fa | perl -pe 's/(\w+\.\w+)\.(\d+) (\d+)/$1\t$2\t$3/' | sort -k1,1 -k3nr,3nr | top_line.awk | awk '{print ">" $1 "." $2}' | sort > tmp.longest

fasta_to_zero_lines.awk vigan.Gyeongwon.a3.v1.peptide.fa | sort > tmp.fa.1ln

join tmp.longest tmp.fa.1ln | perl -pe 's/ zqz /\n/' > vigan.Gyeongwon.gnm3.ann1.3Nz5f.protein_primaryTranscript.faa

changes: 

2018-03-03 Added MANIFEST files
2018-09-15 Changed fastas to include full prefixing (s/vigan/vigan.Gyeongwon.gnm3.ann1/)
```
