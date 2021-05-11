# Pathway Assignments

Pathway assignments are represented in a single file in the appropriate /annotations/ directory.

Filename: _gensp.strain.gnm.ann.KEY4_.pathway.tsv or _gensp.strain.gnm.ann.KEY4.genefamilyversion.KEY4_.pathway.tsv

In the first case, the pathway assignments were copied over from a source like Plant Reactome. 
In the second case, the pathway assignments were _derived from gene family membership_, 
using a source species that has entries in a source like Plant Reactome.

The file has three columns:
1. pathway identifier (e.g. R-9640760.1)
2. pathway name (e.g. G1 phase)
3. LIS gene identifier (e.g. vigun.IT97K-499-35.gnm1.ann1.Vigun02g072800)
```
R-1119260.1   Cardiolipin biosynthesis     phavu.G19833.gnm1.ann1.Phvul.002G231100
R-1119260.1   Cardiolipin biosynthesis     phavu.G19833.gnm1.ann1.Phvul.003G077300
R-1119260.1   Cardiolipin biosynthesis     phavu.G19833.gnm1.ann1.Phvul.008G000300
```
NOTE: the Plant Reactome prefixes should be stripped off (e.g. R-PVU-1119260.1 --> R-1119260.1)
so that genes from different species and strains can be associated with the same pathways.
