# Genetic directory

A /genetic/ directory contains genetic data, without reference to a genome assembly. There is no genomic information associated with genetic markers:
positions on chromosomes are provided elsewhere in GFFs under /markers/.

Directory name: /genetic/*population*.gen.*Author1_Author2_year* or /genetic/*population*.gwas.*Author1_Author2_year*

population:
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

## Linkage groups file (lg.tsv)
Filename: *gensp.population*.gen.*Author1_Author2_year*.lg.tsv

Linkage groups are provided by two columns in the lg file, e.g.
```
#linkage_group    length
TT_Tifrunner_x_GT-C20_c-A01    176.02
TT_Tifrunner_x_GT-C20_c-A02    185.7
TT_Tifrunner_x_GT-C20_c-A03    192.46
TT_Tifrunner_x_GT-C20_c-A04    181.96
TT_Tifrunner_x_GT-C20_c-A05    240.13
```

## Markers file (mrk.tsv)
Filename: *gensp.population*.gen.*Author1_Author2_year*.mrk.tsv

Genetic marker positions on linkage groups (in cM) are provided in the mrk file.
1. marker ID
2. linkage group ID
3. position (cM)
```
A01_859822  A01 0.00
B01_151023  A01 0.75
A01_304818  A01 2.18
```

## OBO file (obo.tsv)
Filename: *gensp.population*.gen.*Author1_Author2_year*.obo.tsv

The OBO file relates traits to ontology terms, e.g.
```
#trait	ontology_identifier
Early leaf spot   TO:0000439
Late leaf spot    TO:0000439
Tomato spotted wilt virus TO:0000148
```

## QTL-marker file (qtlmrk.tsv)
Filename: *gensp.population*.gen.*Author1_Author2_year*.obo.tsv

The QTL-marker file relates QTLs to markers that define them. There are three fields, the first two required:
1. **QTL identifier** (e.g. Early leaf spot 1-2)
2. **marker identifier** (e.g. B05_22527171)
3. marker distinction (flanking or nearest)
```
Early leaf spot 1-1   A08_35596996  flanking
Early leaf spot 1-1   A08_35776787  flanking
Early leaf spot 1-2   B05_22527171  flanking
Early leaf spot 1-2   B05_20207815  flanking
Early leaf spot 1-3   A06_15094465  flanking
```

## QTL file (qtl.tsv)
Filename: *gensp.population*.gen.*Author1_Author2_year*.qtl.tsv

The QTL file relates specific QTL identifiers to traits, along with linkage group placement and other optional data:
1. **QTL identifier**
2. **trait name**
3. linkage group
4. start (cM)
5. end (cM)
6. peak (cM)
7. favored allele source
8. LOD
9. likelihood ratio
10. marker r2
11. total r2
12. additivity 
```
Early leaf spot 1-1 Early leaf spot TT_Tifrunner_x_GT-C20_c-A08 100.7 102.9 102  3.02  12.42 0.56
Early leaf spot 1-2 Early leaf spot TT_Tifrunner_x_GT-C20_c-B05 78.0  80.2  80   10.02 47.42 -1.01
Early leaf spot 1-3 Early leaf spot TT_Tifrunner_x_GT-C20_c-A06 76.9  77.59 77   5.25  17.36 -0.27
Early leaf spot 1-4 Early leaf spot TT_Tifrunner_x_GT-C20_c-B03 27.7  29.2  29   5.96  20.35 0.28
```

## Trait file (trait.tsv)
Filename: *gensp.population*.gen.*Author1_Author2_year*.trait.tsv

Some publications provide information on how traits are measured. This file presents that with trait and description columns.
```
Late leaf spot	LLS resistance score at 70 DAS of 2004, 2005, 2006, 2008, 2009; LLS score at 90 DAS of 2005, 2006, 2009
Rust, Puccinia	Rust resistance score at 70 DAS of 2014; 80 DAS of 2006, 2007E, 2007L, 2008, 2009; Rust score at 90 DAS of 2006, 2007E, 2007L
```

## GWAS results file (results.tsv)
Filename: *gensp.population*.gwas.*Author1_Author2_year*.results.tsv

Note 1: GWAS results and other files from a GWAS are placed in a .gwas. directory, not a .gen. directory.

Note 2: GWAS results are associated with traits, not QTLs. (GWAS do not determine QTLs, they determine individual marker-trait associations with associated significance.)

GWAS results are presented in a file with three columns:
1. trait (e.g. Seed weight)
2. marker (e.g. Affx-152042939)
3. p-value (e.g. 9.12e-9)
```
100 Seed weight from Florida-7 NAM  Affx-152042939  9.12e-9
100 Pod weight from Florida-7 NAM   Affx-152042939  9.12e-9
100 Seed weight from Florida-7 NAM  Affx-152030262  2.82e-7
```

## MST map file (mstmap.tsv)
Filename: *gensp.population*.gt.*Author1_Author2_year*.mstmap.tsv

Note: Genotyping files like these have .gt. rather than .gen. in their names.

An MST map file is a matrix file containing genotyping data, originating at UC-Riverside: http://alumni.cs.ucr.edu/~yonghui/mstmap.html

It is similar to a VCF, but it does not provide genomic locations for the markers. Columns are plant lines, with the first row providing a name; 
rows are markers, with the first column providing the marker name. It may contain a header, described in the URL above.

The genotype states can be specified with letters 'A', 'a', 'B', 'b', '-', 'U' or 'X'. 'A' and 'a' are equivalent, 
'B' and 'b' are equivalent and so are '-' and 'U'. 'U' and '-' indicate a missing genotype call. If the data set is from a RIL population,
you can use 'X' to indicate that the corresponding genotype is a heterozygous 'AB'. The values can also be diploid call pairs like 'AA', 'CC', 'AC', etc.
```
locus_name  46/503-01 46/503-02 46/503-06 46/503-061 46/503-064 ...
2_15811     B         A         B         A          B          ...
2_45924     b         a         b         a          b          ...
2_11663     B         A         B         A          B          ...
2_11664     b         a         b         a          b          ...
```
