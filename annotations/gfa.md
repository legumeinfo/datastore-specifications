# Gene Family Assignments (gfa.tsv)

Gene family assignments are represented in a single GFA file (per family set, e.g. against legfed_v1_0) in the appropriate annotations directory.

Filename: *gensp.strain.gnm.ann.KEY4.genefamilyversion.KEY4*.gfa.tsv

The file has five tab-delimited columns. All but the fifth are required.

1. **gene ID** (full LIS identifier of the gene)
2. **gene family ID** (LIS identifier of the gene family)
3. **protein ID** (full LIS identifier of the protein)
4. **e-value** (statistical significance of the assignment)
5. score (optional score value)

Example: phalu.G27455.gnm1.ann1.JD7C.legfed_v1_0.M65K.gfa.tsv

```
phalu.G27455.gnm1.ann1.tig000546640010 legfed_v1_0.L_00CL8T    phalu.G27455.gnm1.ann1.tig000546640010.1 2.4e-68 271
phalu.G27455.gnm1.ann1.Pl03G0000192100 legfed_v1_0.L_SZRD9F    phalu.G27455.gnm1.ann1.Pl03G0000192100.1 1.4e-90 314
```
