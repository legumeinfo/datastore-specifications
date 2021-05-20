# genetic

A /genetic/ directory contains genetic data, without reference to a genome assembly.
For example, no genomic information is provided for genetic markers: positions on chromosomes are provided elsewhere in GFFs under /markers/.

Directory name:
*population*.gen.*Author1_Author2_year*
*population*.gwas.*Author1_Author2_year*

*population*:
- the name of a RIL collection, e.g. `MAGIC-2017`
- the name of a biparental cross, e.g. `CB27_x_IT82E-18`
- `mixed` if an assortment of lines that doesn't have a particular name

```
/Vigna/unguiculata/genetic/MAGIC-2017.gen.Huynh_Ehlers_2018
├── README.MAGIC-2017.gen.Huynh_Ehlers_2018.yml
├── vigun.MAGIC-2017.gen.Huynh_Ehlers_2018.lg.tsv
├── vigun.MAGIC-2017.gen.Huynh_Ehlers_2018.mrk.tsv
├── vigun.MAGIC-2017.gen.Huynh_Ehlers_2018.obo.tsv
├── vigun.MAGIC-2017.gen.Huynh_Ehlers_2018.qtlmrk.tsv
└── vigun.MAGIC-2017.gen.Huynh_Ehlers_2018.qtl.tsv

/Vigna/unguiculata/genetic/mixed.gen.Burridge_Schneider_2017
├── README.mixed.gen.Burridge_Schneider_2017.yml
├── vigun.mixed.gen.Burridge_Schneider_2017.obo.tsv
├── vigun.mixed.gen.Burridge_Schneider_2017.qtlmrk.tsv
└── vigun.mixed.gen.Burridge_Schneider_2017.qtl.tsv

/Arachis/hypogaea/genetic/NAMFlor7.gwas.Gangurde_Wang_2020/
├── arahy.NAMFlor7.gwas.Gangurde_Wang_2020.obo.tsv
├── arahy.NAMFlor7.gwas.Gangurde_Wang_2020.result.tsv
├── arahy.NAMFlor7.gwas.Gangurde_Wang_2020.trait.tsv
└── README.NAMFlor7.gwas.Gangurde_Wang_2020
```

## README
The README file has two special fields:
- genotyping_platform: the name of the SNP chip or other genotyping platform, hopefully present under the /markers/ directory
- genotyping_method: specifics about the genotyping method used in this study

Also, biparental crosses take a single genotype array entry, e.g.
```
genotype: 
  - CB27 x IT82E-18
  - Sanzi x Vita 7
```
