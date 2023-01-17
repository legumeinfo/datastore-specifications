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
The "primary" files may be absent if the given annotation set does not represent splicing variants.

Note that although the GFF3 specification does not require that every feature have an ID attribute specified, this is required for any gff3 to be loaded into Intermine. IDs typically follow the convention _gensp.strain.gnmVERSION.annVERSION.ORIGINAL_NAME_ although if no ORIGINAL_NAME is supplied, we will generate an ID by appending type and sequential count to the ID of the Parent feature (if any).

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
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.short_summary.json
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.full_table.tsv.gz

where lineage indicates the busco target (e.g. fabales_odb10)
