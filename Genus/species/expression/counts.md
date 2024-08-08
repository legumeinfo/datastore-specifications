# Counts file
optional inclusion

Expression values are provided in a tabular matrix file with LIS gene IDs as the row names and sample identifiers as the column names. Note that despite being non-integers in many cases, these counts are not length or library size normalized. 

The header line contains `geneID` followed by tab-delimited sample identifiers. It is NOT preceded by a #!

Example:
```
gene_id SRX759698       SRX763343       SRX763347       SRX763348       SRX763349       SRX767475       SRX767476       SRX768286       SRX768287       SRX769753       SRX769757       SRX769787       SRX769788       SRX769789       SRX769790       SRX816181       SRX977877       SRX977878       SRX977910       SRX977922
pissa.Cameor.gnm1.ann1.Psat0s1002g0040  0       0       0       3.593   1      0
        3.576   0       0       1       0       0       1.067   0       1.116  0
        0       1       1       1
```
