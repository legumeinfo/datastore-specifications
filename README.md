# datastore-specifications
Specifications for directory naming, file naming, file contents in the LIS datastore

Any of the file-containing directories can contain a README file and a CHANGES file.

## README YAML files
Every file-containing directory, AKA "collection", in the LIS datastore should contain a README file in YAML format. 

Filename: [README.[collection].yml](README.collection.yml)

Examples:
- [README.IT97K-499-35.gnm1.QnBW.yml](https://legumeinfo.org/data/v2/Vigna/unguiculata/genomes/IT97K-499-35.gnm1.QnBW/README.IT97K-499-35.gnm1.QnBW.yml)
- [README.IT97K-499-35.gnm1.ann1.zb5D.yml](https://legumeinfo.org/data/v2/Vigna/unguiculata/annotations/IT97K-499-35.gnm1.ann1.zb5D/README.IT97K-499-35.gnm1.ann1.zb5D.yml)
- [README.CB27_x_IT82E-18.gen.Pottorff_Li_2014.yml](https://legumeinfo.org/data/v2/Vigna/unguiculata/genetic/CB27_x_IT82E-18.gen.Pottorff_Li_2014/README.CB27_x_IT82E-18.gen.Pottorff_Li_2014.yml)

### Validation
The basic README structure (acceptable field names, strings vs. lists vs. dates) can be validated using the following command:
```
pajv -s readme.schema.json -d README.[collection].yml --all-errors --coerce-types=array --remove-additional=all --changes
```
using the JSON schema definition [readme.schema.json](/readme.schema.json).

*This schema must be kept up to date along with the sample template [README.collection.yml](/README.collection.yml) when any changes are made to the README spec.*

### Content requirements
READMEs must be YAML-compliant, which means they pass the test on http://www.yamllint.com/ or using the `yamllint` command-line utility. Here are some, but not all, requirements for a valid LIS README:
- `identifier` at the top repeats the name of the collection, i.e. the name of the containing directory.
- `synopsis` should be short, 100 characters or less.
- `genotype` is a YAML array: but use a single "strain1 x strain2" value for bi-parental crosses.
- DOIs are DOIs, not URLs (e.g. 10.1534/g3.118.200521).
- Dates are in the format 2020-03-23.
- Use spaces, not tabs (*tabs may not appear anywhere in a YAML*)
- Enclose values in quotes when they contain a colon or quotes (you can use single or double quotes to distinguish from quotes in content)
- Leave missing values blank - do not use "N/A" or "none" or anything else.

## CHANGES files
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
