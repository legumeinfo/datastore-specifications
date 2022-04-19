## Markers file (mrk.tsv)

Filename:
- *gensp.population*.map.*Author1_Author2_year*.mrk.tsv
- *gensp.population*.map.*Mapname*.mrk.tsv

*population*:
- the name of a biparental cross, e.g. `BAT93_x_JALOEEP558`
- the name of a RIL population, e.g. `MAGIC-2017`
- `mixed` if an assortment of lines that doesn't have a particular name

*Mapname* may be used rather than *Author1_Author2_year* to expose the name of a widely-used consensus map, such as "GmComposite2003".

Header (required):
```
#marker linkage_group position
```

Examples:
```
phavu.BAT93_x_JALOEEP558.map.Blair_Cortés_2018.mrk.tsv
vigun.MAGIC-2017.map.Huynh_Ehlers_2018.mrk.tsv
glyma.mixed.map.GmComposite2003.mrk.tsv
```

Genetic marker positions on linkage groups (in cM) are provided in the mrk file.

1. marker identifier
2. linkage group identifier
3. position (cM)

Examples:

`phavu.BAT93_x_JALOEEP558.map.Blair_Cortés_2018.mrk.tsv`
```
#marker         linkage_group                        position
TOG905303_749   BAT93_x_JALOEEP558_c-phavu.ChrLG01   0.0
TOG894760_112   BAT93_x_JALOEEP558_c-phavu.ChrLG01   16.9
TOG898020_461   BAT93_x_JALOEEP558_c-phavu.ChrLG01   24.1
TOG895571_1208  BAT93_x_JALOEEP558_c-phavu.ChrLG01   26.6
TOG895571_420   BAT93_x_JALOEEP558_c-phavu.ChrLG01   26.6
...
```

`vigun.MAGIC-2017.map.Huynh_Ehlers_2018.mrk.tsv`
```
#marker  linkage_group  position
2_24641  MAGIC-2017_1   0.0000
2_38890  MAGIC-2017_1   0.3063
2_03520  MAGIC-2017_1   9.7469
...
```

`glyma.mixed.map.GmComposite2003.mrk.tsv`
```
#marker linkage_group        position
A242_1  GmComposite2003_B2   33.13
A144_1  GmComposite2003_I    32.42
A688_1  GmComposite2003_I    32.40
A233_1  GmComposite1999_J    119.90
SAC7_1  GmComposite1999_E    20.40
A454_1  GmComposite1999_E    39.10
...
```
