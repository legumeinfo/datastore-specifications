# Gene Family Assignments (gfa.tsv)

Gene family assignments are represented in a single GFA file (per family set, e.g. against legfed_v1_0) in the appropriate annotations directory.

Filename: *gensp.strain.gnm.ann.KEY4.genefamilyversion.KEY4*.gfa.tsv

The file is tab-delimited with a header:
```
#gene   family  protein e-value score   best_domain_score   pct_hmm_coverage
```
The first five columns are required.

1. **gene ID** (full LIS identifier of the gene)
2. **gene family ID** (LIS identifier of the gene family)
3. **protein ID** (full LIS identifier of the protein)
4. **e-value** (statistical significance of the assignment)
5. **score** (full sequence score value)
6. best_domain_score (score for the single best region hitting the given gene family from the given sequence; generally will be nearly identical to the full sequence score but may be informative when deviations occur in cases like the example shown below)
7. pct_hmm_coverage (calculated as the sum of the length of individual regional alignment divided by the model length; overlaps not currently taken into account, so values above 100 are possible)

Example: phalu.G27455.gnm1.ann1.JD7C.legfed_v1_0.M65K.gfa.tsv
```
#gene   family  protein e-value score   best_domain_score   pct_hmm_coverage
phalu.G27455.gnm1.ann1.Pl05G0000245800  legfed_v1_0.L_VGPXY9    phalu.G27455.gnm1.ann1.Pl05G0000245800.1    7.3e-48 163.8   163.1   100
phalu.G27455.gnm1.ann1.Pl02G0000319200  legfed_v1_0.L_R9W97B    phalu.G27455.gnm1.ann1.Pl02G0000319200.1    6.2e-130    432.9   432.7   99.57805907173
```
Example of a best_domain_score and pct_hmm_coverage suggesting a tandem gene fusion:
```
#gene   family  protein e-value score   best_domain_score   pct_hmm_coverage
phalu.G27455.gnm1.ann1.Pl09G0000096600  legfed_v1_0.L_3GVM33    phalu.G27455.gnm1.ann1.Pl09G0000096600.1    0   2453.5  1286.2  191.035548686244
```

Example of a low pct_hmm_coverage suggesting a gene fragment (e-value and score without reference to a better match as seen below may be hard to judge):
```
#gene   family  protein e-value score   best_domain_score   pct_hmm_coverage
phalu.G27455.gnm1.ann1.Pl03G0000097100  legfed_v1_0.L_MSPJL3    phalu.G27455.gnm1.ann1.Pl03G0000097100.1    4.2e-62 211.5   211.1   19.4489465153971
phalu.G27455.gnm1.ann1.Pl03G0000353700  legfed_v1_0.L_MSPJL3    phalu.G27455.gnm1.ann1.Pl03G0000353700.1    0   1132.0  1131.7  87.1961102106969
```

