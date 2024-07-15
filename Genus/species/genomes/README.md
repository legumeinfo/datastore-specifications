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

<hr>

## Handling haplotype-resolved genome assemblies and annotations

### Background
Until recently, a plant genome sequence could be assumed to consist of sequences corresponding to 1n chromosomes, 
plus some remaining unplaced scaffolds, and maybe also plastid genomes.

Sequencing technology has matured to the point that some assemblies are being generated that include two haplotypes 
for a nuclear genome -- that is, for a genome with 1n chromosomes, both chromatids per chromosome are sequenced, 
  and 2n chromosomes are reported. How should these be represented in the Data Store?

### Consensus best practice within the Data Store:
For diploid or diploidized allotetraploid genomes (cases which until recently have been represented with 1n 
chromosome sequences), separate the assembly and annotations into collections by haplotype.
For the first haplotype (generally considered primary in the haplotype-resolved assemblies we have seen to-date),
leave the collection un-tagged; and for the second haplotype, tag the genome assembly with _hap2.

Examples:
```
Cercis/canadensis/annotations/ISC453364.gnm3.ann1.3N1M
Cercis/canadensis/annotations/ISC453364.gnm3_hap2.ann1.G88H

Cercis/canadensis/genomes/ISC453364.gnm3.GWXB
Cercis/canadensis/genomes/ISC453364.gnm3_hap2.2S7P


Chamaecrista/fasciculata/ISC494698.gnm1.ann1.G7XW
Chamaecrista/fasciculata/ISC494698.gnm1_hap2.ann1.WXZF

Chamaecrista/fasciculata/ISC494698.gnm1.8Q19
Chamaecrista/fasciculata/ISC494698.gnm1_hap2.G6BY
```

<b>Rationale for separating haplotypes most cases:</b>
Many applications and formats presume 1n representation -- for example, VCF, with reference and alternate alleles per SNP location. Also, at least Phytozome is representing haploid-resolved genomes in two sets (similar to option 2).

### Exceptions:
Autopolyploid genomes in which all chromosome copies are sequenced and presumed to be analyzed together
(alfalfa being the only such example we have seen to-date [2024]):
Represent such assemblies with a single collection per genome and annotation set, and with a single genome_main file that contains all chromosomes.
In the case of alfalfa (2n = 4x = 32), this could be handled as e.g.
`  Chr1_hap1, Chr1_hap2, Chr1_hap3, Chr1_hap4`
or some similar pattern; for example, in the case of XinJiangDaYe, the chromosomes are named e.g.
`  Chr1.1, Chr1.2, Chr1.3, Chr1.4`
Directory and file naming in such cases will follow the typical pattern for genomes and assemblies, e.g.
```
  Medicago/sativa/genomes/XinJiangDaYe.gnm1.12MR/
  Medicago/sativa/annotations/XinJiangDaYe.gnm1.ann1.RKB9/
```

### Instructions for preparing genome assembly and annotation files for the Data Store
Because of the large numbers of files involved in genome assembly and annotation files,
it is best to prepare these with a scripted process. We are using the `ds_souschef.pl` script for this purpose.
See detailed notes here, with examples about data-handling for data from several different sorces:

https://github.com/legumeinfo/datastore-specifications/tree/main/PROTOCOLS/ds_souschef_prep_examples


