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
Check the newly created metadata table. It will likely take some manual editing, depending on the data submitted for each category. Often, the original "name" contents are best copied to "description" and the "name" contents supplanted by a more concise shorthand. This will copy column 2 to column 3:
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

Analogous to the above, remove the second column from alternate salmon output file:
```
cut -f 1,3- rnaseq_out/star_salmon/salmon.merged.gene_counts_length_scaled.tsv
```
5) coexpression.tsv

The following script will produce "coexpression.tsv", a table containing covariance and Pearson correlation coefficient statistics for each gene comparisons pair with a PCC at or above a hardcoded threshold of 0.7. It also outputs a separate matrix for both of these two stats with values for all comparisons. These may be deleted if not desired. Requires the doParallel package (within the doparallel conda environment).
```
Rscript --vanilla  co_metrics.R rnaseq_out/star_salmon/salmon.merged.gene_counts.tsv
```
gzip all .tsvs before loading to datastore.

6) replicate_group.bw

Run the script make_bigwigs.sh:
./make_bigwigs.sh <samples.tsv.gz> <chromosome_sizes_file>

NOTE:

- This requires three functions from USCS: bigWigMerge, bedGraphToBigWig and bedSort. All are part of the bigwigmerge conda environment. 

- The working directory should be where the .bam alignments are.

- The .bw files from the sample replicate groups are merged (Column 9 of the samples.tsv). These groups are determined by the curator and do not necessarily reflect the divisions of the experiment. For example, bigwigs might include all samples of the same tissue, but different time points.

- The chromosome sizes file consists of the first two columns of the .fai

