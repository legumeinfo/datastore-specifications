# annotations

Genome annotations are stored in directories under /annotations/.

Directory name: _strain.gnmVERSION.annVERSION.KEY4_
(Note that there should always exist a corresponding representation of the annotated genome under /genomes/, with a different KEY4 but sharing the same prefix up to gnmVERSION)

Files:
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.cds.fna.gz
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.cds.fna.gz.fai
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.cds.fna.gz.gzi
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.cds_primaryTranscript.fna.gz
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.cds_primaryTranscript.fna.gz.fai
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.cds_primaryTranscript.fna.gz.gzi
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.gene_models_main.gff3.gz
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.gene_models_main.gff3.gz.tbi
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.genefamname_.gfa.tsv.gz
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.pathway.tsv.gz
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.protein.faa.gz
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.protein.faa.gz.fai
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.protein.faa.gz.gzi
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.protein_primaryTranscript.faa.gz
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.protein_primaryTranscript.faa.gz.fai
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.protein_primaryTranscript.faa.gz.gzi
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.transcript.fna.gz
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.transcript.fna.gz.fai
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.transcript.fna.gz.gzi
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.transcript_primaryTranscript.fna.gz
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.transcript_primaryTranscript.fna.gz.fai
- _gensp.strain.gnmVERSION.annVERSION.KEY4_.transcript_primaryTranscript.fna.gz.gzi

Note that all fasta files should be bgzipped and faidx indexed.
Note that "primaryTranscript" files may be absent if the given annotation set does not represent splicing variants.

Note that although the GFF3 specification does not require that every feature have an ID attribute specified, this is required for any gff3 to be loaded into Intermine. IDs typically follow the convention _gensp.strain.gnmVERSION.annVERSION.ORIGINAL_NAME_ although if no ORIGINAL_NAME is supplied, we will generate an ID by appending type and sequential count to the ID of the Parent feature (if any).
