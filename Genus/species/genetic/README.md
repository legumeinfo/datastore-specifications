# genetic

A /genetic/ directory contains data from a particular genetic study, without reference to a genome assembly.
For example, no genomic information is provided for genetic markers: positions on chromosomes are provided elsewhere in GFFs under /markers/.

Directory name:
*population*.gen.*Author1_Author2_year*
*population*.gwas.*Author1_Author2_year*


*population*:
- the name of a biparental cross, e.g. `CB27_x_IT82E-18`
- the name of a RIL population, e.g. `MAGIC-2017`
- `mixed` if an assortment of lines that doesn't have a particular name

Examples:

```
QTL study:
/Vigna/unguiculata/genetic/MAGIC-2017.gen.Huynh_Ehlers_2018/
├── README.MAGIC-2017.gen.Huynh_Ehlers_2018.yml
├── vigun.MAGIC-2017.gen.Huynh_Ehlers_2018.obo.tsv
├── vigun.MAGIC-2017.gen.Huynh_Ehlers_2018.qtlmrk.tsv
└── vigun.MAGIC-2017.gen.Huynh_Ehlers_2018.qtl.tsv

GWAS:
/Arachis/hypogaea/genetic/NAMFlor7.gwas.Gangurde_Wang_2020/
├── arahy.NAMFlor7.gwas.Gangurde_Wang_2020.obo.tsv
├── arahy.NAMFlor7.gwas.Gangurde_Wang_2020.result.tsv
├── arahy.NAMFlor7.gwas.Gangurde_Wang_2020.trait.tsv
└── README.NAMFlor7.gwas.Gangurde_Wang_2020
```

## README
The README file has up to three special additional fields:
- **genotyping_platform**: *required for GWAS* the name of the SNP chip or other genotyping platform, hopefully present under the /markers/ directory
- **genotyping_method**: specifics about the genotyping method used in this particular study, optional
- **genetic_map**: *required for QTL studies* the name of the genetic map containing linkage groups on which genetic markers are placed, hopefully present under the /maps/ directory

Also, biparental crosses take a single genotype array entry, e.g.
```
genotype: 
  - CB27 x IT82E-18
```
