# QTL file (qtl.tsv)
Filename: *gensp.population*.gen.*Author1_Author2_year*.qtl.tsv

The QTL file places specific QTL identifiers and their traits on genetic maps + linkage groups with some other optional data:
1. **QTL identifier**
2. **trait name**
3. **genetic map**
4. **linkage group**
5. **start (cM)**
6. **end (cM)**
7. peak (cM)
8. favored allele source
9. LOD
10. likelihood ratio
11. marker r2
12. total r2
13. additivity

Header (required):
```
#qtl_identifier trait_name genetic_map linkage_group start end [peak favored_allele_source lod likelihood_ratio  marker_r2 total_r2  additivity]
```
Example:
```
Early leaf spot 1-1 Early leaf spot TT_Tifrunner_x_GT-C20_c A08 100.7 102.9 102  3.02  12.42 0.56
Early leaf spot 1-2 Early leaf spot TT_Tifrunner_x_GT-C20_c B05 78.0  80.2  80   10.02 47.42 -1.01
Early leaf spot 1-3 Early leaf spot TT_Tifrunner_x_GT-C20_c A06 76.9  77.59 77   5.25  17.36 -0.27
Early leaf spot 1-4 Early leaf spot TT_Tifrunner_x_GT-C20_c B03 27.7  29.2  29   5.96  20.35 0.28
```

NOTE: some QTLs are associated with a single marker, and therefore do not span a region of a linkage group. In that case, **do** list the QTL in the qtl.tsv file with equal start and end positions.
