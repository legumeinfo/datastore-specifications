# expression

Expression files contain RNA-seq expression data (usually in TPM) for an expression experiment, typically drawn from NCBI SRA.

The collection identifier starts with the standard genome annotation identifier `Strain1.gnm.ann` indicating the genome _to which the reads were mapped_.

The collection identifier is then followed by `expr` to indicate an expression collection,
then `Strain2` indicating the genotype of the samples, and finally `Author1_Author2_Year` derived from the contributors,
usually the first two authors and year of a publication.

If the experiment uses samples from more than one genotype, use "mixed" as `Strain2` in the collection name,
and list all of the sample genotypes under `README.genotype`. (The samples file lists the genotype for each sample.)

```
Phaseolus/vulgaris/expression/G19833.gnm1.ann1.expr.Negro_jamapa.ORourke_Iniguez_2014/
├── phavu.G19833.gnm1.ann1.expr.Negro_jamapa.ORourke_Iniguez_2014.obo.tsv.gz
├── phavu.G19833.gnm1.ann1.expr.Negro_jamapa.ORourke_Iniguez_2014.samples.tsv.gz
├── phavu.G19833.gnm1.ann1.expr.Negro_jamapa.ORourke_Iniguez_2014.values.tsv.gz
└── README.G19833.gnm1.ann1.expr.Negro_jamapa.ORourke_Iniguez_2014.yml
```

File names:
- _gensp.collection_.obo.tsv.gz
- _gensp.collection_.samples.tsv.gz
- _gensp.collection_.values.tsv.gz
- _README.collection_.yml.gz

### README
The `genotype` attribute contains a list of all of the sample genotypes.

Expression collection READMEs require an additional special field which denotes the units of expression used in the values file:
- `expression_unit`: the unit of expression, e.g. TPM

In addition, three NCBI-related fields should be filled in, if appropriate:
- `bioproject`
- `geoseries`
- `sraproject`
