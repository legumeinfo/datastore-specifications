# OBO file
Ontology terms are associated with samples in the OBO file as follows. There may be multiple ontology terms associated with a single sample.
1. **sample identifier** the identifier used for the sample in the other files
2. **ontology_term** an OBO term, like PO:0025034

Header:
```
#sample_id  ontology_term
```

Example:
```
#sample_id    ontology_term
SRR1569274    PO:0025034
SRR1569385    PO:0025034
SRR1569432    PO:0009047
SRR1569463    PO:0009006
SRR1569464    PO:0009046
```
