# pangenes

Pan-gene collections are stored under the GENUS/pangenes directories.

Directory name: _strain.panVERSION.KEY4_
The _strain_ will generally be "mixed", since pan-genes are comprised of multiple accessions and possibly multiple species.

The contents of a pan-gene collection include: 
- Fasta sequences (CDS and protein) containing sequence representatives (exemplars) for each pan-gene;
- A "hsh.tsv" file in two-column hash format;
- A "clust.tsv" file in a format with pan-ID in the first column followed by a list of genes;
- A "counts.tsv" file, consisting of a matrix of counts of genes from each annotation, for each pan-gene;
- A "stats.txt" file, with summary information about annotation collections used in the pan-gene calculation, and run parameters.

Example of the ".hsh.tsv" format:
```
phase.pan1.pan00001	phaac.Frijol_Bayo.gnm1.ann1.Phacu.CVR.003G135500.1
phase.pan1.pan00001	phaac.W6_15578.gnm2.ann1.Phacu.WLD.003G129400.1
phase.pan1.pan00001	phaac.Frijol_Bayo.gnm1.ann1.Phacu.CVR.003G133500.1
phase.pan1.pan00001	phalu.G27455.gnm1.ann1.Pl03G0000176400.1
```

Example of the "clust.tsv" (only the first three fields are shown for these rows):
```
phase.pan1.pan00001	phaac.Frijol_Bayo.gnm1.ann1.Phacu.CVR.003G135500.1	phaac.W6_15578.gnm2.ann1.Phacu.WLD.003G129400.1
phase.pan1.pan00002	phaac.Frijol_Bayo.gnm1.ann1.Phacu.CVR.011G222700.1	phaac.W6_15578.gnm2.ann1.Phacu.WLD.011G221300.1
phase.pan1.pan00003	phaac.Frijol_Bayo.gnm1.ann1.Phacu.CVR.001G171100.1	phaac.W6_15578.gnm2.ann1.Phacu.WLD.001G165100.1
```

The collection can (and should) be prepared using ds_souschef.pl (in datastore-specification/scripts/),
with pangene config; see examples at scripts/ds_souschef_configs/pangene_sets/ .

The primary pan-gene sets are calculated using the [pandagma](https://github.com/legumeinfo/pandagma) pipeline 
(unless coming from an external published source; in that case, the "supplements" data type may be the more appropriate location).

### Files expected in a pan-gene collection:

#### Pan-gene list files:
- gensp.mixed.panVERSION.KEY4.clust.tsv.gz: Pan-gene sets, in cluster format: ID in first column, then tab-separated gene list.
- gensp.mixed.panVERSION.KEY4.hsh.tsv.gz: Pan-gene sets, in a two-column hash format.

#### Fasta files: representing the pan-genes, and also the remaining sequences that didn't find a pan-gene to join.
- gensp.mixed.panVERSION.KEY4.complement.fna.gz: Complement of genes in this pan-gene set; i.e. not clustered.
- gensp.mixed.panVERSION.KEY4.inclusive_cds.fna.gz: CDS pan-gene sequence, inclusive (not filtered by minimum cluster size).
- gensp.mixed.panVERSION.KEY4.inclusive_protein.faa.gz: Protein pan-gene sequence, inclusive (not filtered).

#### Then sequence files, with some filtering and with derived pan-gene IDs based on consensus chromosome and ordinal position:
- gensp.mixed.panVERSION.KEY4.pctl25_named_cds.fna.gz: CDS sequences, omitting pan-genes < 25% of the mode.
- gensp.mixed.panVERSION.KEY4.pctl25_named_protein.faa.gz: Protein sequences, omitting pan-genes < 25% of the mode.
- gensp.mixed.panVERSION.KEY4.pctl25_named_trim_cds.fna.gz: CDS sequences, omitting pan-genes < 25% of the mode.
- gensp.mixed.panVERSION.KEY4.pctl25_named_trim_protein.faa.gz: Protein sequencess, omitting pan-genes < 25% of the mode.

#### Statistics and reports:
- gensp.mixed.panVERSION.KEY4.counts.tsv.gz: Matrix of counts of genes per annotation set for each pan-gene set.
- gensp.mixed.panVERSION.KEY4.stats.txt.gz: Descriptive statistics about program parameters, input sequences, and products.

The percentile value "pctl25_named" files may vary (might be e.g. pctl50 or pctl33, depending on filtering parameters).

All FASTA files should be bgzipped and faidx indexed.

The tabular (.tsv) files shouild be bgzipped.

