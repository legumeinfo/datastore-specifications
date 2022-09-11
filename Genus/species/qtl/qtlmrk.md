# QTL-marker file (qtlmrk.tsv)
Filename: *gensp.population*.gen.*Author1_Author2_year*.qtlmrk.tsv

The QTL-marker file relates QTLs to markers that define them. There are four fields, the first three required:
1. **QTL identifier** (e.g. Early leaf spot 1-2)
2. **Trait name** (e.g. Early leaf spot)
3. **Marker identifier** (e.g. B05_22527171)
4. marker distinction (flanking or nearest)

Note that *this file also associates QTLs with traits,* and may be the only file that does so since the qtl.tsv file places QTLs on linkage groups,
which are not always measured. Also, we do not place markers on linkage groups here; that is done in collections under /maps/. But the marker distinction
is a QTL-specific attribute so it appears here.

Header (required):
```
#qtl_identifier trait_name  marker  linkage_group [distinction]
```

Example:
```
Seed protein 21-11      Seed protein    flanking
Seed yield 15-15        Seed yield      flanking
Pod maturity 16-1       Pod maturity    peak
```
