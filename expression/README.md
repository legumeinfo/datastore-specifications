# expression

Expression files contain RNA-seq expression data (usually in TPM) for an expression experiment, typically drawn from NCBI SRA.

```
Phaseolus/vulgaris/expression/G19833.gnm1.ann1.expr.4ZDQ/
├── phavu.G19833.gnm1.ann1.expr.4ZDQ.obo.tsv
├── phavu.G19833.gnm1.ann1.expr.4ZDQ.samples.tsv
├── phavu.G19833.gnm1.ann1.expr.4ZDQ.values.tsv
└── README.G19833.gnm1.ann1.expr.4ZDQ.yml
````

Directory name: *strain.gnm.ann*.expr.*KEY4*

File names:
*gensp.strain.gnm.ann*.expr.*KEY4*.obo.tsv
*gensp.strain.gnm.ann*.expr.*KEY4*.samples.tsv
*gensp.strain.gnm.ann*.expr.*KEY4*.values.tsv
README.*gensp.strain.gnm.ann*.expr.*KEY4*.yml

There are three NCBI-related fields expected to be filled in the README, if appropriate:
- bioproject
- geoseries
- sraproject

