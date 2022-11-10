# qtl

A **/qtl/** directory contains data from a particular QTL, without reference to a genome assembly.
For example, no genomic information is provided for genetic markers: positions on chromosomes are provided elsewhere in GFFs under /markers/.

Directory name:
*population*.qtl.*Author1_Author2_year*

*population*:
- the name of a biparental cross, e.g. `CB27_x_IT82E-18`
- the name of a RIL population, e.g. `MAGIC-2017`
- `mixed` if an assortment of lines that doesn't have a particular name

Example:

```
/Vigna/unguiculata/qtl/MAGIC-2017.qtl.Huynh_Ehlers_2018/
├── README.MAGIC-2017.qtl.Huynh_Ehlers_2018.yml
├── vigun.MAGIC-2017.qtl.Huynh_Ehlers_2018.obo.tsv
├── vigun.MAGIC-2017.qtl.Huynh_Ehlers_2018.qtlmrk.tsv
└── vigun.MAGIC-2017.qtl.Huynh_Ehlers_2018.qtl.tsv
```

## README
The README file has up to three special additional fields:
- **genetic_map**: optional, the name of the genetic map(s) (comma-separated if more than one) containing linkage groups on which the QTLs and genetic markers are placed
- **genotyping_platform**: optional, comma-separated list of genotyping platforms, hopefully present under the /markers/ directory
- **genotyping_method**: optional, specifics about the genotyping method used in this particular study

Also, biparental crosses take a single genotype array entry, e.g.
```
genotype: 
  - CB27 x IT82E-18
```
