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

The collection can (and should) be prepared using ds_souschef.pl (in datastore-specification/scripts/),
with pangene config; see examples at scripts/ds_souschef_configs/pangene_sets/ .
The primary pan-gene sets are calculated using the [pandagma](https://github.com/legumeinfo/pandagma) pipeline 
(unless coming from an external published source; in that case, the "supplements" data type may be the more appropriate location).

Required files:
- _gensp.mixed.panVERSION.KEY4_clust.tsv.gz: Pan-gene sets, in cluster format: ID in first column, followed by tab-separated gene list.
- _gensp.mixed.panVERSION.KEY4_counts.tsv.gz: Matrix of counts of genes per annotation set for each pan-gene set.
- _gensp.mixed.panVERSION.KEY4_hsh.tsv.gz: Pan-gene sets, in a two-column hash format, with the set ID in the first column and genes in the second.
- _gensp.mixed.panVERSION.KEY4_complement.fna.gz: Complement of genes in this pan-gene set; i.e. not clustered, presumed to be singletons.
- _gensp.mixed.panVERSION.KEY4_inclusive_cds.fna.gz: CDS pan-gene sequence, inclusive (not filtered by minimum cluster size or annotation-set representation).
- _gensp.mixed.panVERSION.KEY4_inclusive_protein.faa.gz: Protein pan-gene sequence, inclusive (not filtered by minimum cluster size or annotation-set representation).
- _gensp.mixed.panVERSION.KEY4_pctl25_named_cds.fna.gz: CDS pan-gene sequence, omitting pan-genes smaller than 25% of the mode, with derived pan-gene IDs corresponding with consensus chromosome and ordinal position.
- _gensp.mixed.panVERSION.KEY4_pctl25_named_protein.faa.gz: Protein pan-gene sequence, omitting pan-genes smaller than 25% of the mode, with derived pan-gene IDs corresponding with consensus chromosome and ordinal position.
- _gensp.mixed.panVERSION.KEY4_pctl25_named_trim_cds.fna.gz: CDS pan-gene sequence, omitting pan-genes smaller than 25% of the mode, and with tandem duplicates reduced.
- _gensp.mixed.panVERSION.KEY4_pctl25_named_trim_protein.faa.gz: Protein pan-gene sequences, omitting pan-genes smaller than 25% of the mode, and with tandem duplicates reduced.
- _gensp.mixed.panVERSION.KEY4_stats.txt.gz: Descriptive statistics about program parameters, input sequences, and pan-gene products.

The percentile value "pctl25_named" files may vary (might be e.g. pctl50 or pctl33).

All FASTA files should be bgzipped and faidx indexed.

The tabular (.tsv) files shouild be bgzipped.

