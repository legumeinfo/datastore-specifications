The first step in generating an expression dataset for the datastore is to obtain a metadata table. This can be conveniently acheived with nextflow's fetchngs pipeline as so:

```
nextflow run nf-core/fetchngs -r 1.12.0 --input SRR_ids.tsv --outdir fetchngs_out -profile singularity --download_method sratools --nf_core_pipeline rnaseq
```

Input file of ids should have .csv or .tsv extension. Default download method is ftp, sratools has proven more reliable. The last argument formats the output in a manner acceptable to the rnaseq pipeline. If stand info isn't available, "auto" is written in the output samplesheet. 

Next, provide the metadata table "samplesheet.csv" to the rnaseq pipeline, along with the genome/annotation:

```
nextflow run nf-core/rnaseq -r 3.14.0 --input samplesheet/samplesheet.csv --outdir rnaseq_out --fasta phavu.G19833.gnm1.zBnF.genome_main.fna --gff phavu.G19833.gnm1.ann1.pScz.gene_models_main.gff -profile singularity
```

As described in the README in this directory of the repository, 3 files from this run need to be staged (in addition to the .yaml detailing the study and publication info):

1) samples.tsv

Format the samplesheet from fetchngs:
```
/data/adf/nf-core/fetchngs/for_rex/create_samples_file.pl --genotype_tag=cultivar samplesheet/samplesheet.csv > formatted_table.tsv
```
Check the newly created metadata table. It will likely take some manual editing, depending on the data submitted for each category. Often, the "name" is best copied "description" and with the original column contents supplanted by a more concise shorthand after this operation:
```
awk 'BEGIN{FS=OFS="\t"} NR!=1 {$3=$2}'1 formatted_table.tsv
```

2) obo.tsv
   
This is most easily attained by cutting the tissue column from the samplesheet, then looking the tissues up at https://planteome.org/po_glossary
Keep in mind that if growth stage data is present, these ontology terms should also be included in the file (comma-delimited from the tissue ontologies per sample).

3) values.tsv

Cut out the second column from this file, that's it:
```
cut -f 1,3- rnaseq_out/star_salmon/salmon.merged.gene_tpm.tsv 
```
