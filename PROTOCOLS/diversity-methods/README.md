# Protocols for converting VCF (Variant Call Format) files to a HapMap(Haplotype) format.

TASSEL(Trait Analysis by aSociation, Evolution and Linkage) is often a preferred tool for converting VCF files to HapMap format.

## How to use TASSEL tool for VCF to HapMap format conversion

TASSEL can be run from command line, which is ideal for HPC environments like Scinet/Ceres with Slurm. Check its availabilty by running 

```bash
module avail tassel

Here is the command to run TASSEL:

run_pipeline.pl -Xmx10g -fork1 -vcf your_input.vcf.gz  -export your_output.hmp.txt -exportType Hapmap -runfork1

```

#### Expanation of command

* run_pipeline.pl: This is the main script to run TASSEL's command-line pipeline.
* -fork1: Starts a new process (often useful for memory management).
* -vcf your_input.vcf.gz: Specifies the input VCF file. TASSEL can handle both uncompressed and bgzip-compressed VCFs automatically.
* -export: Tells TASSEL to export the data.
* -exportType Hapmap: Specifies that the output format should be HapMap.
* -outputFile your_output.hmp.txt: Defines the name and path for your output HapMap file. You can add .gz to the end (e.g., your_output.hmp.txt.gz) if you want compressed output.

### More Steps might needed

You might encounter following error message during the above run. 

java.lang.IllegalStateException: Error Processing VCF block: Mismatch of alleles.

This error is very specific and points directly to an issue TASSEL is having when trying to interpret the allele information in your VCF file. It's a common problem when converting complex VCFs to simpler formats like HapMap, which traditionally expects biallelic SNPs.

### How to Resolve the "Mismatch of alleles" Error:
The best approach is almost always to pre-filter your VCF file to ensure it only contains variants that TASSEL can easily convert to HapMap. You want to aim for biallelic SNPs only.

#### Recommended Approach: Filter with bcftools

```bash 
# Load bcftools module on Ceres

module load bcftools

 Step 1: Normalize and decompose multiallelic sites.
# This command splits multiallelic sites into multiple biallelic records.
# It also left-aligns and normalizes indels.
bcftools norm -m -any --check-ref w -f your_genome_assembly.fa your_input.vcf.gz -o normalized.vcf.gz -Oz

# Step 2: Filter for biallelic SNPs only
bcftools view -v snps -m2 -M2 normalized.vcf.gz -o filtered_biallelic_snps.vcf.gz -Oz

```
#### Explanation of bcftools commands:
* bcftools norm -m -any --check-ref w -f your_genome_assembly.fa your_input.vcf.gz -o normalized.vcf.gz -Oz
    * -m -any: Decomposes multiallelic sites into multiple biallelic records. For example, A/G,T becomes A/G and A/T.
    * --check-ref w: Warns if the VCF's REF allele doesn't match the reference FASTA.
    * -f your_genome_assembly.fa: Crucially, you need to provide your genome assembly FASTA file here. This ensures that bcftools can correctly normalize and validate alleles.
    * -o normalized.vcf.gz -Oz: Outputs the normalized VCF in gzipped format.
* bcftools view -v snps -m2 -M2 normalized.vcf.gz -o filtered_biallelic_snps.vcf.gz -Oz
    * -v snps: Keeps only SNP variants. This filters out indels, MNPs, and structural variants.
    * -m2 -M2: Keeps only biallelic sites (min 2 alleles, max 2 alleles). This is important even after norm -m -any because some original multiallelic sites might have been filtered, and this ensures only simple biallelic SNPs remain.
    * -o filtered_biallelic_snps.vcf.gz -Oz: Outputs the final filtered VCF.

### Once Filtered:

After you've created a filtered_biallelic_snps.vcf.gz file, try running your TASSEL command again using this new, cleaner VCF:

```
module load tassel

run_pipeline.pl -Xmx10g -fork1 -vcf your_input.vcf.gz  -export your_output.hmp.txt -exportType Hapmap -runfork1

```
