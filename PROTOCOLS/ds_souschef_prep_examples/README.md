# Examples of data-preparation protocols for preparing data from various sources.
Notes files in this directory show methods that have been used to prepare files for the Data Store,
transforming incoming data from e.g. GenBank or the CNCB Genome Warehouse (GWH).
Although the notes apply to particular data sets, they are meant to be useable with minimal modification
for similar datasets from these major data sources. Some effort has been made to keep the
notes generic, using variables wherever possible - and to test the notes carefully. Please report errors or questions.

## CNCB Genome Warehouse (GWH)

A challenge with data from GWH is that the assembly molecules (chromomes, scaffolds) are renamed to GWH accessions.

<a href="CNCB_Genome_Warehouse/notes_glyma.Wm82_NJAU.gnm1.ann1.sh">CNCB_Genome_Warehouse/notes_glyma.Wm82_NJAU.gnm1.ann1.sh</a>

## Dealing with distinct haplotype assmeblies and the annotations on those assemblies
For handling an assembly and annotations with two haplotypes, see the `CNCB_Genome_Warehouse` example 
for <i>Phanera championii</i>, and Phytozome examples for <i>Cercis canadensis</i> and <i>Chamaecrista fasciculata</i>.
In the case of <i>Phanera championii</i>, The two haplotype datasets were pulled out of the combined GWH files, 
and then `ds_souschef.pl` was run on each haplotype (using one config for each haplotype).
In the cases of <i>Cercis canadensis</i> and <i>Chamaecrista fasciculata</i>, the haplotypes were separate
in the Phytozome collections, and were kept separate during preparation of the Data Store collections.

<a href="CNCB_Genome_Warehouse/notes_phach.longxuteng.gmn1.ann1_haplotypes.sh">CNCB_Genome_Warehouse/notes_phach.longxuteng.gmn1.ann1_haplotypes.sh</a>

<a href="Phytozome/notes_cerca.ISC453364.gnm3.ann1.sh">notes_cerca.ISC453364.gnm3.ann1.sh</a>
<a href="Phytozome/notes_cerca.ISC453364.gnm3_hap2.ann1.sh">notes_cerca.ISC453364.gnm3_hap2.ann1.sh</a>

<a href="Phytozome/notes_chafa.ISC494698.gnm1.ann1.sh">notes_chafa.ISC494698.gnm1.ann1.sh</a>
<a href="Phytozome/notes_chafa.ISC494698.gnm1_hap2.ann1.sh">notes_chafa.ISC494698.gnm1_hap2.ann1.sh</a>


## NCBI GenBank

Challenges with data from GenBank are:
(1) The assembly molecules (chromomes, scaffolds) are renamed to GenBank accessions;
(2) The GFF structure in RefSeq annotation files is complex, with child features being assigned identifiers that 
can only be traced to parent features via the `Parent=` attribute, rather than via lexical patterns; and
(3) There are many noncoding elements (e.g. snRNA, rRNA, contigs, transcript, pseudogene, lnc_RNA), which aren't handled by gffread.

We have handled these by renaming features relative to the gene ID (e.g. mRNA LOC131625884.1 for gene LOC131625884) and by
separating the annotation into two files -- one with coding elements and one with noncoding elements.

The notes_glyma.NARO_collection.sh is for a set of 11 assemblies and annotations, so has some additional shell loops
that are specific to this job. Also - as of January 2025, this is the first of these notest that
are applied in the Ceres HPC (USDA SciNet).

<a href="NCBI_GenBank/notes_arast.V10309.gnm1.ann1.sh">NCBI_GenBank/notes_arast.V10309.gnm1.ann1.sh</a><br>
<a href="NCBI_GenBank/notes_tripr.HEN17-A07.gnm1.ann1.sh">NCBI_GenBank/notes_tripr.HEN17-A07.gnm1.ann1.sh</a><br>
<a href="NCBI_GenBank/notes_vicvi.HV-30.gnm1.ann1.sh">NCBI_GenBank/notes_vicvi.HV-30.gnm1.ann1.sh</a><br>
<a href="NCBI_GenBank/notes_glyma.NARO_collection.sh">NCBI_GenBank/notes_glyma.NARO_collection.sh</a>

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

## Pangenes

The notes in this section are for preparation of pangene datasets produced by <a href="Pandagma">https://github.com/legumeinfo/pandagma</a>.
They have been tested with output from pandagma v2.0, February 2024, on runs for eight genera: 
Arachis, Cicer, Glycine, Medicago, Phaseolus, and Vigna.

<a href="Pangenes/notes_Phaseolus.pan3.sh">Pangenes/notes_Phaseolus.pan3.sh</a>

## Instructions for installing packages into a conda environment, "ds-curate", on Ceres

First time: create conda environment and install 

``` bash
  salloc -N 1 -n 36 -t 2:00:00 -p short
    # you may want to make an alias for this invocation in your ~/.bashrc, e.g. 
    #    alias interact="salloc -N 1 -n 36 -t 2:00:00 -p short"

  ml miniconda
  conda create -n ds-curate
  source activate ds-curate
  conda install -n ds-curate -c conda-forge -c bioconda \
    bioconda::perl-yaml-tiny bioconda::perl-bioperl bioconda::samtools \
    conda-forge::ncbi-datasets-cli bioconda::gffread

  npm install -g ajv-cli ajv-formats
```

Subsequently, at the start of a session:

``` bash
  salloc -N 1 -n 36 -t 2:00:00 -p short

  ml miniconda
  source activate ds-curate

  npm install -g ajv-cli ajv-formats
```

