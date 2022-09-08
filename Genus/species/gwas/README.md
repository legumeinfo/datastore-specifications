# gwas

A /gwas/ directory contains data from a particular GWAS, without reference to a genome assembly.
For example, no *genomic* information is provided for genetic markers: positions on chromosomes are provided elsewhere in GFFs under /markers/.

Directory name:
*population*.gwas.*Author1_Author2_year*

*population*:
- the name of a biparental cross, e.g. `CB27_x_IT82E-18`
- the name of a RIL population, e.g. `MAGIC-2017`
- `mixed` if an assortment of lines that doesn't have a particular name

Example:

```
/Arachis/hypogaea/genetic/NAMFlor7.gwas.Gangurde_Wang_2020/
├── arahy.NAMFlor7.gwas.Gangurde_Wang_2020.obo.tsv
├── arahy.NAMFlor7.gwas.Gangurde_Wang_2020.result.tsv
├── arahy.NAMFlor7.gwas.Gangurde_Wang_2020.trait.tsv
└── README.NAMFlor7.gwas.Gangurde_Wang_2020
```

## README
The README file has up to three special additional fields:
- **genotyping_platform**: *required* the name of the SNP chip or other genotyping platform, hopefully present under the /markers/ directory
- **genotyping_method**: specifics about the genotyping method used in this particular study, optional

Also, biparental crosses take a single genotype array entry, e.g.
```
genotype: 
  - CB27 x IT82E-18
```
