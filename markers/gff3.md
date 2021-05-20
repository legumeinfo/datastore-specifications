# marker GFF file

This file defines all of the marker-specific attributes as well as its position on a given genome. Loaders should refer to this file to get details on markers such as alleles and type of marker.

## GFF3 records
- use `genetic_marker` as the feature type
- The `ID` attribute is optional and is a unique identifier within the GFF. Examples: ss1234567 or 12345. **Loaders should not use ID**, as it may be missing or have arbitrary values.
- The **`Name`** attribute is required and provides the identifier of the marker, not specific to a particular genome, for linking it to the same marker in genetic files (e.g. GWAS files or genetic linkage mapping files). Example: ss1234567.
- The `Type` attribute is optional and labels the type of marker (eg. Type=SNP).
- The `Alleles` attribute is optional (e.g. Alleles=A/G). The alleles should correspond to the forward strand of the given genome assembly.
- The `Alias` attribute is optional (e.g. Alias=BARC-008209-00048).

Glycine/max/markers/Wm82.gnm2.mrk.SoySNP50K/glyma.Wm82.gnm2.mrk.SoySNP50K.gff3.gz
```
##gff-version 3
glyma.Wm82.gnm2.Gm19  SoySNP50K genetic_marker  41346674  41346674  . - . ID=ss1235986311;Name=ss1235986311;Alleles=G/T;Type=SNP
```
