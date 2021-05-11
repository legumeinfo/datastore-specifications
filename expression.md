# Expression

Expression files contain RNA-seq expression data (usually in TPM) for an expression experiment, typically drawn from NCBI SRA.
```
Phaseolus/vulgaris/expression/G19833.gnm1.ann1.expr.4ZDQ/
├── phavu.G19833.gnm1.ann1.expr.4ZDQ.obo.tsv
├── phavu.G19833.gnm1.ann1.expr.4ZDQ.samples.tsv
├── phavu.G19833.gnm1.ann1.expr.4ZDQ.values.tsv
└── README.G19833.gnm1.ann1.expr.4ZDQ.yml
````
Directory name: expression/*strain.gnm.ann*.expr.*KEY4*

File names:
*gensp.strain.gnm.ann*.expr.*KEY4*.obo.tsv
*gensp.strain.gnm.ann*.expr.*KEY4*.samples.tsv
*gensp.strain.gnm.ann*.expr.*KEY4*.values.tsv
README.*gensp.strain.gnm.ann*.expr.*KEY4*.yml

There are three NCBI-related fields expected to be filled in the README, if appropriate:
- bioproject
- geoseries
- sraproject

## Samples file
Samples are provided in a multicolumn tab-delimited data file. Only the first two are required.
1. **sample name** (human-readable like Root Tip)
1. **sample key** (typically a BioProject accession like SRR1569474)
1. sample uniquename
1. sample description
1. treatment
1. tissue
1. development stage
1. age
1. organism (*Genus species*)
1. infraspecies
1. cultivar
1. application
1. sra_run
1. biosample_accession
1. sra_accession
1. bioproject_accession
1. sra_study

```
Leaf Young	SRR1569274	Leaf Young (SRR1569274)	YL: Fully expanded 2nd trifoliate leaf tissue from plants provided with fertilizer	Leaf Young	Leaf Young			Phaseolus vulgarisNegro jamapa	Nitrate fertilizer	SRR1569274	SAMN02226068	SRS696906	PRJNA210619	SRP046307
Leaf 21 DAI	SRR1569385	Leaf 21 DAI (SRR1569385)	LF:  Leaf tissue from fertilized plants collected at the same time of LE and LI(not included in this dataset)	Leaf 21 DAI	Leaf 21 DAI		Phaseolus vulgaris		Negro jamapa	Nitrate fertilizer	SRR1569385	SAMN02226070	SRS696939	PRJNA210619	SRP046307
```

## Values file
Expression values are provided in a tabular matrix file with LIS gene IDs as the row names and sample keys as the column names.

```
geneID    SRR1569274    SRR1569385    SRR1569432    SRR1569463    SRR1569464    SRR1569465    SRR1569467    SRR1569468    SRR1569469    SRR1569471    SRR1569472    SRR1569473    SRR1569474SRR1569475    SRR1569477
phavu.G19833.gnm1.ann1.Phvul.001G000100    2.45    0.7    1.8    2.33    1.56    0.76    1.41    1.07    1.75    1.53    1.97    0.6    2.77    1.11    1.03
phavu.G19833.gnm1.ann1.Phvul.001G000200    0    0.08    0    0    0    0    0.02    0    0    0    0    0    0    0    0
phavu.G19833.gnm1.ann1.Phvul.001G000300    15.04    3.1    20.08    30    23.25    12.78    17.11    9.08    14.39    20.64    13.41    11.71    24.27    13.4    19.6
```

## OBO file
Ontology terms are associated with samples in the OBO file as follows. There may be multiple ontology terms associated with a single sample.

```
#sample_id    ontology_term
SRR1569274    PO:0025034
SRR1569385    PO:0025034
SRR1569432    PO:0009047
SRR1569463    PO:0009006
SRR1569464    PO:0009046
```
