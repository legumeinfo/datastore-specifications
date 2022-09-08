## GWAS result file (result.tsv)
Filename: *gensp.population*.gwas.*Author1_Author2_year*.result.tsv

Note 1: GWAS results and other files from a GWAS are placed in a .gwas. collection/directory, not a .gen. collection/directory.

Note 2: GWAS results are associated with traits, not QTLs. (GWAS do not determine QTLs, they determine individual marker-trait associations with associated significance.)

GWAS results are presented in a result.tsv file with three columns, all required:
1. **trait name** e.g. Seed weight
2. **marker** e.g. Affx-152042939
3. **p-value** e.g. 9.12e-9

Header (required):
```
#trait_name marker  pvalue
```

Example:
```
100 Seed weight from Florida-7 NAM  Affx-152042939  9.12e-9
100 Pod weight from Florida-7 NAM   Affx-152042939  9.12e-9
100 Seed weight from Florida-7 NAM  Affx-152030262  2.82e-7
```
