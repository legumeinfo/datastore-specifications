# annotations

Genome annotations are stored in directories under /annotations/.

Directory name: _strain.gnmVERSION.annVERSION.KEY4_
(Note that there should always exist a corresponding representation of the annotated genome under /genomes/, with a different KEY4 but sharing the same prefix up to gnmVERSION)

Required files:
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.cds.fna.gz
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.cds.fna.gz.fai
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.cds.fna.gz.gzi
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.gene_models_main.gff3.gz
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.gene_models_main.gff3.gz.tbi
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.genefamname.gfa.tsv.gz
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.pathway.tsv.gz
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.protein.faa.gz
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.protein.faa.gz.fai
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.protein.faa.gz.gzi
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.mrna.fna.gz
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.mrna.fna.gz.fai
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.mrna.fna.gz.gzi

Optional files:
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.cds_primary.fna.gz
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.cds_primary.fna.gz.fai
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.cds_primary.fna.gz.gzi
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.featid_map.tsv.gz
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.protein_primary.faa.gz
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.protein_primary.faa.gz.fai
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.protein_primary.faa.gz.gzi
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.mrna_primary.fna.gz
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.mrna_primary.fna.gz.fai
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.mrna_primary.fna.gz.gzi

All FASTA files should be bgzipped and faidx indexed.
The "primary" files may be absent if the given annotation set does not represent splicing variants. If the "primary" files are present, they should all represent the same isoform selections, which will typically be done choosing the longest translated protein; NB: this may mean that the mrna file does not contain the longest transcribed isoforms. Subselection of primary proteins and cds can be accomplished using the longest_variant_from_fasta.sh script; selection of the corresponding mrnas can then be done using something like:
```
samtools faidx --region-file <(awk '{print $1}' vicfa.Hedin2.gnm1.ann1.PTNK.cds_primary.fna.gz.fai) vicfa.Hedin2.gnm1.ann1.PTNK.mrna.fna.gz | bgzip -l9 -c > vicfa.Hedin2.gnm1.ann1.PTNK.mrna_primary.fna.gz
```

Note that although the GFF3 specification does not require that every feature have an ID attribute specified, this is required for any gff3 to be loaded into Intermine. IDs typically follow the convention _gensp.strain.gnmVERSION.annVERSION.ORIGINAL_NAME_ although if no ORIGINAL_NAME is supplied, we will generate an ID by appending type and sequential count to the ID of the Parent feature (if any).

The _Name_ attribute will be a required attribute in all `gene_models_main.gff3` files. The intended purpose of the name will be as described in [the gff3 specification](https://github.com/The-Sequence-Ontology/Specifications/blob/master/gff3.md): "Display name for the feature. This is the name to be displayed to the user. Unlike IDs, there is no requirement that the Name be unique within the file." 

Where available in the original annotations, the names should come from those annotation files, with the possible exception of stripping type identifiers (e.g. "gene:"), or shortening exceptionally cumbersome auto-generated strings or lengthy prefixes added in the original annotation form if those prefixes do not contribute to the uniqueness of the names within the annotation file. Such exceptions will need to be considered on a case-by-casse basis. 

When gene Name is not supplied in the original annotation file, it should be determined from the sequence files (CDS, mRNA, protein) if those are available. If only the annotation file is provided (and the sequence files need to be generated using e.g. gffread), then the name should correspond with the "un-prefixed" ID. For example, given the identifier `glycy.G1267.gnm1.ann1.Gcy1g000849`, the Name would be `Gcy1g000849`.

The following are examples of acceptable names:

| ID | Name | Reason |
| :--- | :---: | :---- |
| arahy.Tifrunner.gnm1.ann1.HA8THR | HA8THR | OK |
| arahy.Tifrunner.gnm2.ann2.Ah01g088800 | Ah01g088800 | OK |
| araip.K30076.gnm1.ann1.Araip.L423N | Araip.L423N | OK (prefix original) |
| glydo.G1134.gnm1.ann1.Gtt1g000960 | Gtt1g000960 | OK |
| glyma.Wm82.gnm1.ann1.Glyma01g21510 | Glyma01g21510 | OK |
| glyma.Wm82.gnm2.ann1.Glyma.01G067400 | Glyma.01G067400 | OK (prefix original) |
| glyma.Zh13_IGA1005.gnm1.ann1.SoyZH13_01R004482 | SoyZH13_01R004482 | OK |
| phavu.UI111.gnm1.ann1.PvUI111.01G074900 | PvUI111.01G074900 | OK (prefix original) |
| trisu.Daliak.gnm2.ann1.Ts_00473 | Ts_00473 | OK |
| vigra.VC1973A.gnm6.ann1.Vradi01g06280 | Vradi01g06280 | OK |
| vigun.UCR779.gnm1.ann1.VuUCR779.01G029300 | VuUCR779.01G029300 | OK (prefix original) |
| medtr.A17.gnm5.ann1_6.MtrunA17Chr1g0152141 | MtrunA17Chr1g0152141 | OK


The following are examples of **UN**acceptable names (and the reason): 

| ID | Name | Reason |
| :--- | :---: | :---- |
| cajca.ICPL87119.gnm1.ann1.C.cajan_04851 | cajca.C.cajan_04851 | gratuitous prefix |
| cicar.CDCFrontier.gnm1.ann1.Ca_02646 | cicar.CDCFrontier.Ca_02646 | gratuitous prefix |
| cicar.ICC4958.gnm2.ann1.Ca_00646 | cicar.ICC4958.Ca_00646 | gratuitous prefix |
| glyma.Hwangkeum.gnm1.ann1.GmHk_01G000541 | exosc3_1 | doesn't correspond with ID or sequences |
| lupal.Amiga.gnm1.ann1.gene:Lalb_Chr01g0003511 | lupal.Lalb_Chr01g0003511 | gratuitous prefix |
| lupan.Tanjil.gnm1.ann1.Lup031547 | lupan.Lup031547 | gratuitous prefix |
| medtr.HM004.gnm1.ann1.g876 | HM004.g876 | gratuitous prefix |
| tripr.MilvusB.gnm2.ann1.gene6109 | tripr.gene6109 | gratuitous prefix

<hr>

The featid_map.tsv.gz file contains two tab-separated fields: before_feature_ID  prefixed_feature_ID
Examples:
```
VradiU00002412	vigra.VC1973A.gnm7.ann1.VradiU00002412
VradiU00002412.1	vigra.VC1973A.gnm7.ann1.VradiU00002412.1
VradiU00002412.1:exon:104	vigra.VC1973A.gnm7.ann1.VradiU00002412.1:exon:104
```
```
GmISU01.01G000050	glyma.Wm82_ISU01.gnm2.ann1.GmISU01.01G000050
GmISU01.01G000050.1	glyma.Wm82_ISU01.gnm2.ann1.GmISU01.01G000050.1
GmISU01.01G000050.1.CDS.1	glyma.Wm82_ISU01.gnm2.ann1.GmISU01.01G000050.1.CDS.1
```

A BUSCO subfolder contains the results of running BUSCO analysis against the primary protein sequences for one or more BUSCO lineages. The result files will be:
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.busco._lineage_.short_summary.txt
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.busco._lineage_.short_summary.json
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.busco._lineage_.full_table.tsv.gz

where lineage indicates the busco target (e.g. fabales_odb10)
