# Linkage groups file (lg.tsv)

Filename:
- *gensp.population*.map.*Author1_Author2_year*.mrk.lg
- *gensp.population*.map.*mapname*.lg.tsv

*population*:
- the name of a biparental cross, e.g. `BAT93_x_JALOEEP558`
- the name of a RIL population, e.g. `MAGIC-2017`
- `mixed` if an assortment of lines that doesn't have a particular name

*Mapname* may be used rather than *Author1_Author2_year* to expose the name of a widely-used consensus map, such as "GmComposite2003".

Examples:
```
phavu.BAT93_x_JALOEEP558.map.Blair_Cortés_2018.lg.tsv
vigun.MAGIC-2017.map.Huynh_Ehlers_2018.lg.tsv
glyma.mixed.map.GmComposite2003.lg.tsv
```

Linkage groups are defined by two columns in the lg.tsv file:

1. linkage group identifier
2. length (cM)

Examples:

`phavu.BAT93_x_JALOEEP558.map.Blair_Cortés_2018.lg.tsv`
```
#linkage_group                      length
BAT93_x_JALOEEP558_c-phavu.ChrLG01  145.5
BAT93_x_JALOEEP558_c-phavu.ChrLG02  140.6
BAT93_x_JALOEEP558_c-phavu.ChrLG03  114.4
...
```

`vigun.MAGIC-2017.map.Huynh_Ehlers_2018.lg.tsv`
```
#linkage_group  length
MAGIC-2017_1    86.3426
MAGIC-2017_2    72.5654
MAGIC-2017_3    132.6856
...
```

`glyma.mixed.map.GmComposite2003.lg.tsv`
```
#linkage_group      length
GmComposite2003_A1  102.30
GmComposite2003_A2  165.72
GmComposite2003_B1  131.81
GmComposite2003_B2  120.98
GmComposite2003_C1  135.62
GmComposite2003_C2  157.89
...
```
