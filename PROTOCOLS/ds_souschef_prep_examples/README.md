# Examples of data-preparation protocols for preparing data from various sources.
Notes files in this directory show methods that have been used to prepare files for the Data Store,
transforming incoming data from e.g. GenBank or the CNCB Genome Warehouse (GWH).
Although the notes apply to particular data sets, they are meant to be useable with minimal modification
for similar datasets from these major data sources. Some effort has been made to keep the
notes generic, using variables wherever possible - and to test the notes carefully. Please report errors or questions.

## CNCB Genome Warehosue (GWH)

A challenge with data from GWH is that the assembly molecules (chromomes, scaffolds) are renamed to GWH accessions.

For handling an assembly and annotations with two haplotypes, see the example for <i>Phanera championii</i>. The general
processing strategy (as of early 2024) is to pull the two haplotype datasets out of the combined GWH files, 
then run `ds_souschef.pl` on each haplotype (using one config for each haplotype), then move the respective files
back into a single Data Store collection directory.

<a href="CNCB_Genome_Warehouse/notes_glyma.Wm82_NJAU.gnm1.ann1.sh">CNCB_Genome_Warehouse/notes_glyma.Wm82_NJAU.gnm1.ann1.sh</a>
<a href="CNCB_Genome_Warehouse/notes_phach.longxuteng.gmn1.ann1_haplotypes.sh">CNCB_Genome_Warehouse/notes_phach.longxuteng.gmn1.ann1_haplotypes.sh</a>

## NCBI GenBank

Challenges with data from GenBank are (1) the assembly molecules (chromomes, scaffolds) are renamed to GenBank accessions, and
(2) The GFF structure is complex, with child features being assigned identifiers that can only be traced to parent features
via the `Parent=` attribute, rather than via lexical patterns.

<a href="NCBI_GenBank/notes_arast.V10309.gnm1.ann1.sh">NCBI_GenBank/notes_arast.V10309.gnm1.ann1.sh</a>

## Phytozome

The phytozome assemblies and annotations are quite regular and are generally handled well by `ds_souschef.pl`,
but there are some challenges particular to these annotations. The Phytozome annotations have a
version suffix in the gene.gff3 file, e.g. `.v1.1` in `Phcoc.01G000300.v1.1`; 
and the IDs in the protein files have a `.p` suffix, e.g. `Phcoc.L027000.1.p`.
Currently (early 2024), these are best handled by stripping the version suffix from IDs in the gff3 file,
and in the `ds_souschef.pl` config file, add e.g. `strip: '\.p'` for the protein files.

<a href="Phytozome/notes_phaco.PHA8298.gnm1.ann1.sh">Phytozome/notes_phaco.PHA8298.gnm1.ann1.sh</a>

## Dryad

Assemblies and annotations at Dryad should be assumed to be unique per Dryad collection. They are whatever was submitted; Dryad imposes no constraints on format or quality.

<a href="Dryad/notes_acacr.Acra3RX.gmn1.ann1.sh">Dryad/notes_acacr.Acra3RX.gmn1.ann1.sh</a>

