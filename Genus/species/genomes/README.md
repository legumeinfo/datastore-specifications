# genomes

Genome assemblies are stored in directories under /genomes/.

Directory name: _strain.gnm.KEY4_

Additional README properties:
- `chromosome_prefix` identifies sequences in the `genome_main.fna` that correspond to chromosomes
- `supercontig_prefix` identifies sequences in the `genome_main.fna` that correspond to supercontigs

Files:
- README._strain.gnm.KEY4_.yml
- _gensp.strain.gnm.KEY4_.genome_main.fna.gz
- _gensp.strain.gnm.KEY4_.genome_main.fna.gz.fai
- _gensp.strain.gnm.KEY4_.genome_main.fna.gz.gzi
- _gensp.strain.gnm.KEY4_.seqid_map.tsv.gz

A BUSCO subfolder contains the results of running BUSCO analysis against the genomic sequence for one or more BUSCO lineages. The result files will be:
- _gensp.strain.gnm.KEY4_.busco._lineage_.short_summary.txt
- _gensp.strain.gnm.KEY4_.busco._lineage_.short_summary.json
- _gensp.strain.gnm.KEY4_.busco._lineage_.full_table.tsv.gz

where lineage indicates the busco target (e.g. fabales_odb10)

