# maps

A /maps/ directory contains genetic maps, without reference to a genome assembly.
No genomic information is provided for genetic markers: positions on chromosomes are provided elsewhere in GFFs under /markers/.

Directory name:
- *population*.map.*Author1_Author2_year*
- *population*.map.*Mapname*

*population*:
- the name of a biparental cross, e.g. `BAT93_x_JALOEEP558`
- the name of a RIL population, e.g. `MAGIC-2017`
- `mixed` if an assortment of lines that doesn't have a particular name

*Mapname* may be used rather than *Author1_Author2_year* to expose the name of a widely-used consensus map, such as "GmComposite2003".

Examples:

```
/Phaseolus/vulgaris/maps/BAT93_x_JALOEEP558.map.Blair_Cortés_2018
├── README.BAT93_x_JALOEEP558.map.Blair_Cortés_2018.yml
├── phavu.BAT93_x_JALOEEP558.map.Blair_Cortés_2018.lg.tsv.gz
└── phavu.BAT93_x_JALOEEP558.map.Blair_Cortés_2018.mrk.tsv.gz

/Vigna/unguiculata/maps/MAGIC-2017.map.Huynh_Ehlers_2018
├── README.MAGIC-2017.map.Huynh_Ehlers_2018.yml
├── vigun.MAGIC-2017.map.Huynh_Ehlers_2018.lg.tsv.gz
└── vigun.MAGIC-2017.map.Huynh_Ehlers_2018.mrk.tsv.gz

/Glycine/max/maps/mixed.map.GmComposite2003
├── README.mixed.map.GmComposite2003.yml
├── glyma.mixed.map.GmComposite2003.lg.tsv.gz
└── glyma.mixed.map.GmComposite2003.mrk.tsv.gz
```

## README
The README file requires one special additional field:
- genetic_map: the name of the genetic map as referenced in /genetic/ READMEs, e.g. "GmComposite2003" or "BAT93_x_JALOEEP558_c".

In general, linkage group names are formed from *genetic_map* and *LGname* such as "GmComposite2003_N" or "BAT93_x_JALOEEP558_c-phavu.ChrLG01".

Also, biparental crosses take a single genotype array entry, e.g.
```
genotype: 
  - BAT93 x JALOEEP558
```
