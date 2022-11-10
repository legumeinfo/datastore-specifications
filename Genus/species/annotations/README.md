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
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.genefamname_.gfa.tsv.gz
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
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.protein_primary.faa.gz
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.protein_primary.faa.gz.fai
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.protein_primary.faa.gz.gzi
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.mrna_primary.fna.gz
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.mrna_primary.fna.gz.fai
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.mrna_primary.fna.gz.gzi

All FASTA files should be bgzipped and faidx indexed.
The "primary" files may be absent if the given annotation set does not represent splicing variants.

Note that although the GFF3 specification does not require that every feature have an ID attribute specified, this is required for any gff3 to be loaded into Intermine. IDs typically follow the convention _gensp.strain.gnmVERSION.annVERSION.ORIGINAL_NAME_ although if no ORIGINAL_NAME is supplied, we will generate an ID by appending type and sequential count to the ID of the Parent feature (if any).
