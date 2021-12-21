# datastore-specifications
Specifications for directory naming, file naming, file contents in the LIS datastore

Any of the file-containing directories can contain a README file and a CHANGES file.

## README YAML files

Every file-containing directory, AKA "collection", in the LIS datastore should contain a README file in YAML format. 

Filename: README.*collection*.yml see [example in this repository](README.collection.yml)

Examples:
- `README.IT97K-499-35.gnm1.QnBW.yml`
- `README.IT97K-499-35.gnm1.ann1.zb5D.yml`
- `README.CB27_x_IT82E-18.gen.Pottorff_Li_2014.yml`

### Content
The README content must be parseable by the LIS InterMine README parser:
[Readme.java](https://github.com/legumeinfo/lis-bio-sources/blob/0bf2a5650f6f9b2311a1b187ae4c560608743060/lis-datastore/src/main/java/org/intermine/bio/dataconversion/Readme.java)

READMEs must be YAML-compliant, which means they pass the test on http://www.yamllint.com/ or using the `yamllint` command-line utility.

### Requirements
- When in doubt, enclose values in quotes.
- `identifier` at the top repeats the name of the collection.
- `synopsis` should be short, 100 characters or so.
- DOIs are DOIs, not URLs (e.g. 10.1534/g3.118.200521)
- The date format is 2020-03-23.
- Missing data should be left blank; do not use "N/A" or "none" or anything else.
- genotype is a YAML array; use the format strain1 x strain2 for bi-parental crosses.
- Do not use a colon within the value unless you enclose the entire value in quotes.

Do not add any attributes without consulting Sam -- additional attributes will *break the InterMine README parser* (until they are added).

## CHANGES file

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
