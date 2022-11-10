# synteny

Synteny data are presented in GFF files in directories under /synteny/.

Directory name: _Strain1.gnm1_.syn._KEY4_

Filenames: _gensp1.Strain1.gnm1_.x._gensp2.Strain2.gnm2_.gff.gz

The first _gensp1.Strain1.gnm1_ matches the name of the collection from the directory name and README.identifier.

The second _gensp2.Strain2.gnm2_ identifies the target genus, species, strain, and assembly version.

Example:
```
IT97K-499-35.gnm1.syn.W3NY
├── vigun.IT97K-499-35.gnm1.x.glyma.Wm82.gnm2.W3NY.gff.gz
├── vigun.IT97K-499-35.gnm1.x.phavu.G19833.gnm1.W3NY.gff.gz
├── vigun.IT97K-499-35.gnm1.x.vigan.Gyeongwon.gnm3.W3NY.gff.gz
├── vigun.IT97K-499-35.gnm1.x.vigra.VC1973A.gnm6.W3NY.gff.gz
└── vigun.IT97K-499-35.gnm1.x.vigun.IT97K-499-35.gnm1.W3NY.gff.gz
```
GFF3 records have the following format:

_gensp1.Strain1.gnm1.chr1_ DAGchainer syntenic\_region _start1_ _end1_ _score_ _strand_ Name=_gensp2.Strain2.gnm2.chr2_;matches=_gensp2.Strain2.gnm2.chr2_:_start2_.._end2_;median_Ks=_float_

Example:
```
vigun.IT97K-499-35.gnm1.Vu01 DAGchainer syntenic_region 64390 1882809 4545.0 - . Name=glyma.Wm82.gnm2.Gm06;matches=glyma.Wm82.gnm2.Gm06:49767515..51299643;median_Ks=0.3641
```
