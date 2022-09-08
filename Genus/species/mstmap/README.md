# mstmap

An /mstmap/ directory contains a UC-Riverside MST map file.

Directory name:
*population*.mst.*Author1_Author2_year*

*population*:
- the name of a biparental cross, e.g. `CB27_x_IT82E-18`
- the name of a RIL population, e.g. `MAGIC-2017`
- `mixed` if an assortment of lines that doesn't have a particular name

Example:

```
/Vigna/unguiculata/genetic/IT84S-2246-4_x_TVu-14676.mst.Pottorff_Roberts_2014
├── CHANGES.IT84S-2246-4_x_TVu-14676.mst.Pottorff_Roberts_2014.txt
├── README.IT84S-2246-4_x_TVu-14676.mst.Pottorff_Roberts_2014.yml
└── vigun.IT84S-2246-4_x_TVu-14676.mst.Pottorff_Roberts_2014.mstmap.tsv.gz
```

## README
The README file has two additional fields:
- **genotyping_platform**: the name of the SNP chip or other genotyping platform, hopefully present under the /markers/ directory
- **genotyping_method**: specifics about the genotyping method used in this particular study, optional

Also, biparental crosses take a single genotype array entry, e.g.
```
genotype: 
  - CB27 x IT82E-18
```
