# genome_alignments

Whole genome alignment data are presented in PAF and BAM files in directories under /genome_alignments/. Although in theory, pairwise alignments ought to be invariant regardless of which order the sequences are given, in practice most file formats (and algorithms) will make a distinction between the sequence used as "query" and that used as "reference". In keeping with convention used elsewhere in the datastore, the first genome listed in the name will be that used as the reference.

Directory name: _Strain1.gnm1.wga.KEY4_

Filenames: 
 - _gensp1.Strain1.gnm1.x.gensp2.Strain2.gnm2.KEY4_.paf.gz
 - _gensp1.Strain1.gnm1.x.gensp2.Strain2.gnm2.KEY4_.bam

The first _gensp1.Strain1.gnm1_ matches the name of the collection from the directory name and README.identifier, and denotes the genome used as the reference in the alignment.

The second _gensp2.Strain2.gnm2_ identifies the query genome genus, species, strain, and assembly version.

Example:
```
CDCFrontier.gnm3.wga.PXV3
cicar.CDCFrontier.gnm3.x.cicre.Besev079.gnm1.PXV3.minimap2.bam
cicar.CDCFrontier.gnm3.x.cicre.Besev079.gnm1.PXV3.minimap2.bam.bai

├── cicar.CDCFrontier.gnm3.x.cicre.Besev079.gnm1.PXV3.minimap2.paf.gz
├── cicar.CDCFrontier.gnm3.x.cicre.Besev079.gnm1.PXV3.minimap2.bam
├── cicar.CDCFrontier.gnm3.x.cicre.Besev079.gnm1.PXV3.minimap2.bam.bai
├── cicar.CDCFrontier.gnm3.x.cicec.S2Drd065.gnm1.PXV3.minimap2.paf.gz
├── cicar.CDCFrontier.gnm3.x.cicec.S2Drd065.gnm1.PXV3.minimap2.bam
└── cicar.CDCFrontier.gnm3.x.cicec.S2Drd065.gnm1.PXV3.minimap2.bam.bai


```
