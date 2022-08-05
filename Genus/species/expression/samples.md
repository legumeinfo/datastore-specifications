# Samples file
Samples are provided in a multicolumn tab-delimited data file. Label each replicate_group if the experiment contains replicates.
1. **identifier** e.g. SAMN02226091 (anything unique, could also be a GEO sample, for example)
2. **name** e.g. Leaf_Young
3. **description** e.g. Fully expanded 2nd trifoliate leaf tissue from plants provided with fertilizer
4. **treatment** e.g. Normal growing conditions
5. **tissue** e.g. leaf
6. **development_stage** e.g. V2 - second trifoliate
7. **species** e.g. Phaseolus vulgaris
8. **genotype** e.g. G19833
9. replicate_group e.g. 1A, leave blank if no reps
10. biosample e.g. SAMN02226068
11. sra_experiment e.g. SRX695793

Header:
```
#identifier  name  description  treatment  tissue  development_stage  species  genotype  replicate_group  biosample  sra_experiment
```

Example:
```
#identifier  name    description                                                                     treatment   tissue  development_stage  species             genotype     replicate_group  biosample     sra_experiment
SRR1569274   YL      Fully expanded 2nd trifoliate leaf tissue from plants provided with fertilizer  fertilized  leaf    2nd trifoliate     Phaseolus vulgaris  Negro jamapa                  SAMN02226068  SRX695793
SRR1569385   LF21DAI Leaf tissue from fertilized plants collected 21 days after implantation         fertilized  leaf    21 DAI             Phaseolus vulgaris  Negro jamapa                  SAMN02226070  SRX695830
```
