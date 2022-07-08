# Samples file
Samples are provided in a multicolumn tab-delimited data file. Only the first two columns are required.
1. **sample name** (human-readable like Root Tip)
2. **sample identifier** (typically a BioProject accession like SRR1569474)
3. sample uniquename
4. sample description
5. treatment
6. tissue
7. development stage
8. age
9. organism (*Genus species*)
10. infraspecies
11. cultivar
12. application
13. sra_run
14. biosample_accession
15. sra_accession
16. bioproject_accession
17. sra_study

Header:
```
#sample_name  sample_id  [sample_uniquename  sample_description  treatment tissue  development_stage age organism  infraspecies  cultivar  application sra_run biosample_accession sra_accession bioproject_accession  sra_study]
```

Example:
```
#sample_name  sample_id sample_uniquename sample_description  treatment tissue  development_stage age organism  infraspecies  cultivar  application sra_run biosample_accession sra_accession bioproject_accession  sra_study
Leaf Young    SRR1569274	Leaf Young (SRR1569274)	YL: Fully expanded 2nd trifoliate leaf tissue from plants provided with fertilizer	Leaf Young	Leaf Young			Phaseolus vulgarisNegro jamapa	Nitrate fertilizer	SRR1569274	SAMN02226068	SRS696906	PRJNA210619	SRP046307
Leaf 21 DAI	SRR1569385	Leaf 21 DAI (SRR1569385)	LF:  Leaf tissue from fertilized plants collected at the same time of LE and LI(not included in this dataset)	Leaf 21 DAI	Leaf 21 DAI		Phaseolus vulgaris		Negro jamapa	Nitrate fertilizer	SRR1569385	SAMN02226070	SRS696939	PRJNA210619	SRP046307
```
