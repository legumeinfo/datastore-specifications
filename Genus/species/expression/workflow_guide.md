The first step in generating an expression dataset for the datastore is to obtain a metadata table. This can be conveniently achieved with nextflow's fetchngs pipeline as so:

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

Cut out the second column from this file:
```
cut -f 1,3- rnaseq_out/star_salmon/salmon.merged.gene_tpm.tsv 
```
4) counts.tsv

Analygous to the above, remove the second column from alternate salmon output file:
```
cut -f 1,3- rnaseq_out/star_salmon/salmon.merged.gene_counts_length_scaled.tsv
```
5) coexpression.tsv

The following script will produce "gene-to-gene_covariance_correlation.tsv" which contains coexpression and Pearson correlation coefficient statistics for all all pairwise gene comparisons. It also output a pair-wise matrix for each of these two stats which may be deleted if not desired. 
```
Rscript --vanilla  /erdos/elavelle/correlation_metrics.R star_salmon_gene_counts.tsv
```
The data should be limited to a 0.7 PCC threshold for the sake of size. This can be accomplished with the following commands:
```
tail -n+2 gene-to-gene_covariance_correlation.tsv | awk '$4 >= .7+0 {print $0}' | sort -gr -k4 > coexpression_sorted.tsv
```
To make a numerical comparison of the data in the 4th column (excluding the header), then sort the rows in descending order by the values in that column (the PCCs). Save the header with:
```
head -1 gene-to-gene_covariance_correlation.tsv > coexpression_header.tsv
```
Then:
```sed '$ d' coexpression_sorted.tsv | awk '$4 != "NA" {print $0}' > coexpression_sorted_filtered.tsv && cat ~/coexpression_header.tsv coexpression_sorted_filtered.tsv > <dataset_prefix>.coexpression.tsv 
```
to remove non-applicable values and tack the header back on.

gzip all .tsvs before loading to datastore.
