# pangenes

Pan-gene collections are stored under the GENUS/pangenes directories.

Directory name: _strain.panVERSION.KEY4_
The _strain_ will generally be "mixed", since pan-genes are comprised of multiple accessions and possibly multiple species.

The contents of a pan-gene collection include: 
- an `hsh.tsv` file
- a `clust.tsv` file
- a `counts.tsv` file, consisting of a matrix of counts of genes from each annotation, for each pan-gene;
- a `stats.txt` file, with summary information about annotation collections used in the pan-gene calculation, and run parameters;
- Fasta files (CDS and protein) containing sequence representatives (exemplars) for each pan-gene;
- Fasta files containing sequences representing the pan-genes themselves.
- two statistics/reports files

The collection can (and should) be prepared using `ds_souschef.pl` (in datastore-specification/scripts/),
with pangene config; see examples at `scripts/ds_souschef_configs/pangene_sets/`.

The primary pan-gene sets are calculated using the [pandagma](https://github.com/legumeinfo/pandagma) pipeline 
(unless coming from an external published source; in that case, the "supplements" subdirectories may be the more appropriate location).

#### Fasta files representing the pan-genes, and also the remaining sequences that didn't find a pan-gene to join.
- `Genus.panVERSION.KEY4.complement.fna.gz`
- `Genus.panVERSION.KEY4.inclusive_cds.fna.gz`
- `Genus.panVERSION.KEY4.inclusive_protein.faa.gz`

#### Protein and CDS sequence Fastas, with some filtering and with derived pan-gene IDs based on consensus chromosome and ordinal position:
- `Genus.panVERSION.KEY4.pctl25_named_cds.fna.gz`: CDS sequences, omitting pan-genes < 25% of the mode.
- `Genus.panVERSION.KEY4.pctl25_named_protein.faa.gz`: Protein sequences, omitting pan-genes < 25% of the mode.
- `Genus.panVERSION.KEY4.pctl25_named_trim_cds.fna.gz`: CDS sequences, omitting pan-genes < 25% of the mode.
- `Genus.panVERSION.KEY4.pctl25_named_trim_protein.faa.gz`: Protein sequencess, omitting pan-genes < 25% of the mode.

#### Statistics and reports:
- `Genus.panVERSION.KEY4.counts.tsv.gz`: Matrix of counts of genes per annotation set for each pan-gene set.
- `Genus.panVERSION.KEY4.stats.txt.gz`: Descriptive statistics about program parameters, input sequences, and products.

The percentile value "pctl25_named" files may vary (might be e.g. pctl50 or pctl33, depending on filtering parameters).

All FASTA files should be bgzipped and faidx indexed.

The tabular (.tsv) files shouild be bgzipped.

### README

There are two additional lists in a pangene collection README:
- `annotations_main`
- `annotations_extra`

Example:
```yaml
annotations_main:
  - cicar.CDCFrontier.gnm3.ann1
  - cicar.ICC4958.gnm2.ann1
  - cicec.S2Drd065.gnm1.ann1
  - cicre.Besev079.gnm1.ann1

annotations_extra:
  - cicar.CDCFrontier.gnm1.ann1
  - cicar.CDCFrontier.gnm2.ann1
```

The README for the collection should validate as a standard datastore "validate.sh readme" file. 
However, note the following differences relative to other genomic collections:
- The "scientific_name" will just be the genus, e.g. Phaseolus.
- The "taxid" should be for the genus level.
- ??? The "scientific_name_abbrev" should be five letters from the genus name, lowercased: "phase", "vigna", "glyci", etc.
- The "genotype" should be a list of the constituent genotypes, as a yaml array (one line per genotype).
- All of the above conventions should be handled automatically by [ds_souschef.pl](https://github.com/legumeinfo/datastore-specifications/tree/main/scripts), given a suitable [config file](https://github.com/legumeinfo/datastore-specifications/tree/main/scripts/ds_souschef_configs/pangene_sets).

