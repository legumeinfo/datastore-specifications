# General protocols: procedures for adding new data, etc.
Instructions for adding data to the datastore and then updating associated LIS/SoyBase/PeanutBase resources.

NOTE: The instructions below are for curators working on files used by
legumeinfo.org, soybase.org, and peanutbase.org.
If you are a researcher or user of and you have a data set that you would like
to contribute, please <a href="https://legumeinfo.org/contact">CONTACT US!</a>
We would love to work with you.

## Table of Contents
[Datastore instances and organization](#datastore-curation) <br>
[General procedure for adding a new data set to the datastore](#adding-to-the-datastore) <br>
[Procedure for adding genome and annotation collections with ds_souschef](#using-souschef) <br>
[Questions and handling hard cases with ds_souschef](#souschef-faq) <br>
[Initiate or update "about_this_collection.yml"](#description-genus-species) <br>
[Calculate AHRD functional annotations](#calc-ahrd) <br>
[Calculate gene family assignments (GFA)](#calc-gfa) <br>
[Add to pan-gene set](#pan-genes) <br>
[Load relevant mine](#mine-loading) <br>
[Add BLAST targets](#blast-targets) <br>
[Incorporate into GCV](#populate-gcv) <br>
[Update the jekyll collections listing](#update-jekyll) <br>
[Update browser configs](#update-browsers) <br>

## General procedure for doing curation work on the datastore <a name="datastore-curation"/>

### Datastore instances and organization
As of January 2025, the datastore is being maintained at three locations:
  - ceres.scinet.usda.gov
  - atlas-login.hpc.msstate.edu
  - soybase-stage.usda.iastate.edu

A nightly cron job syncs these instances in the direction of ceres to soybase-stage and atlas to soybase-stage.
The public content of the datastore is made available via https from the instance at soybase-stage.

<b>The best practice is to do any curation on ceres.</b> The instance at soybase-stage is being used for display
of the data at the relevant urls: https://data.legumeinfo.org and https://data.soybase.org. The instance at 
atlas-login.hpc.msstate.edu is for backup and for data access when ceres is unavailable due to periodic maintenance.

The longer-term plan is for the datastore to be hosted for public access in a USDA Azure instance, with a .gov URL.

"The datastore" is comprised of three directories:
* <b>v2</b>  -- The public datastore, accessed at https://data.legumeinfo.org or https://data.soybase.org
* <b>annex</b>  -- For curated public data that lacks specification or formalized metadata (use judiciously)
* private  -- Staging area; not publicly accessible

There are also three affiliated directories at the same root level:
* conda-envs  -- The conda software environment sufficient for most curation
* datastore-registry  -- For registering "key4" values; tracks https://github.com/legumeinfo/datastore-registry
* datastore-specifications  -- Specifications and documentation, including this README

### Establish an interactive session on a computation node

The [ceres and atlas resources](https://scinet.usda.gov/guides/resources/CeresAtlasDifferences) are a managed HPC environments, 
in which computational work is done either in
an interactive session or via a [SLURM job](https://scinet.usda.gov/guides/use/slurm). 
It is very important not to try to do work beyond simple navigation
or file transfers on the login nodes. Rather, for an interactive session, start a SLURM job:

```
  salloc  # equivalent to   salloc --cpus-per-task=2 --time=12:00:00 --partition=short
```

Or for longer-running jobs, use a [job submission script](https://scinet.usda.gov/guides/use/slurm).
  
### Set paths and start a conda environment with software needed for curation

Software for curation includes both project-specific scripts (validators, formatters, etc.) and third-party tools (gffread, samtools, etc.).

The project-specifc scripts are managed within the present repository, in the 
[scripts directory](https://github.com/legumeinfo/datastore-specifications/tree/main/scripts).

These scripts (and the repository) also has an instance alongside the datastore, at
`/project/legume_project/datastore/datastore-specifications/scripts`. 

For convenience, it is recommended to add this directory to your .bashrc file:
``` bash
  PATH=/project/legume_project/datastore/datastore-specifications/scripts:$PATH
```

Several software packages are needed for many curation tasks, e.g., bioperl, samtools, gffread, yamllint.
These have been loaded into a conda environment. So, at the start of an interactive session, this environment
can be loaded like so:

```
  salloc
  ml miniconda
  source activate /project/legume_project/datastore/conda-envs/ds-curate
```
<details>
To deactivate the conda environment:

  ```
    conda deactivate
  ```
</details>

A variation on this is to add a link to that environment to your local set of .conda environments. 
This has the advantage of reducing the length of the command prompt:

```
  cd ~
  ln -s /project/legume_project/datastore/conda-envs/ds-curate ~/.conda/envs/ds-curate
  echo $PWD/.conda/envs/ds-curate >> ~/.conda/environments.txt
  # then check ~/.conda/environments.txt to make sure you don't have two instances of ds-curate

Then, as above, but
  source activate ds-curate

```
<details>

The following recipe creates a conda environment, `ds-curate`, in a common location,
`/project/legume_project/datastore/conda-envs/`. The environment should be available to all members of the legume_project group.

  ```
  salloc    # equivalent to   salloc --cpus-per-task=2 --time=12:00:00 --partition=short

  ml miniconda
  conda create --prefix /project/legume_project/datastore/conda-envs/ds-curate
  source activate /project/legume_project/datastore/conda-envs/ds-curate
  conda install -c conda-forge -c bioconda \
    bioconda::perl-yaml-tiny bioconda::perl-bioperl bioconda::samtools \
    conda-forge::ncbi-datasets-cli bioconda::gffread \
    conda-forge::yamllint conda-forge::nodejs \
    bioconda::bedtools bioconda::blast

  npm install -g ajv-cli ajv-formats
  ```

</details>


## General procedure for adding a new data set to the datastore <a name="adding-to-the-datastore"/>

### Upload the data to the datastore curation instance
As of January 2025, the datastore is being maintained at three locations:
  - ceres.scinet.usda.gov
  - atlas-login.hpc.msstate.edu
  - soybase-stage.usda.iastate.edu

In general, during preparation, data should initially go into "private" (`/project/legume_project/datastore/private`), in a suitable
subdirectory (organized by genus and species and generally mirroring the organization of "public").

Data can be transferred to "private" using typical methods, e.g. scp or Globus.

### Name the directories and files
Apply directory names, following the patterns described in specifications in this repository.

<u>Note: For genomes and annotation, please see [Automating the process for genome and annotation collections with ds_souschef](#using-souschef)
below, as that tool helps to automate and regularize the process.</u>

Each data "collection," consisting of one or more related data files of a particular type (genome assembly,
annotation, marker set, etc.) has a name consisting of three dot-separated parts or fields (four fields for annotation collections):
genotype.data-type.key-name

For annotation, genome, and synteny collections, the "key-name" is a four-letter string, "checked out" from
this registry: https://github.com/legumeinfo/datastore-registry.
Please see the instructions there for registering keys.
```
  genomes:  CB5-2.gnm1.WDTB  Sanzi.gnm1.YNCM   UCR779.gnm1.M7KZ
  annotations:  CB5-2.gnm1.ann1.0GKC  Sanzi.gnm1.ann1.HFH8   UCR779.gnm1.ann1.VF6G
```
For collections that are typically associated with a publication, the unique "key" has the form "Author\_Author\_YEAR"
```
  genetic: CB27_x_IT82E-18.mst.Pottorff_Li_2014 CB27_x_IT97K-556-6.gen.Huynh_Ehlers_2015
  maps: MAGIC-2017.map.Huynh_Ehlers_2018
  markers: IT97K-499-35.gnm1.mrk.Cowpea1MSelectedSNPs
```
### Fill out the README and MANIFEST files
Fill out the README file. The empty template is at
https://github.com/legumeinfo/datastore-specifications/blob/main/README.collection.yml
but it is often easiest to copy a README from another data collection for the
same species and then change the fields that need to be changed.

Note that the metadata files are in yml format. See a basic description:
https://docs.ansible.com/ansible/latest/reference_appendices/YAMLSyntax.html
We use just a few of the yml features - basically, ...
Start the file with three dashes.
Use the "key : value pattern", for records with a single element -
or the list form, in which all members of a list are lines beginning at the same
indentation level starting with a "- " (a dash and a space).

Fill out the correspondence MANIFEST file, giving correspondence with prior filenames:
```
cat MANIFEST.Wm82.gnm2.DTC4.correspondence.yml
---
# filename in this repository: previous names
glyma.Wm82.gnm2.DTC4.genome_hardmasked.fna.gz: Gmax_275_v2.0.hardmasked.fa.gz
glyma.Wm82.gnm2.DTC4.genome_softmasked.fna.gz: Gmax_275_v2.0.softmasked.fa.gz
```
Fill out the descriptions MANIFEST file, giving a brief one-line description of each data file:
```
cat MANIFEST.Wm82.gnm2.DTC4.descriptions.yml
---
# filename in this repository: description
glyma.Wm82.gnm2.DTC4.hardmasked.fna.gz: Genome assembly: masked with 'N's
glyma.Wm82.gnm2.DTC4.softmasked.fna.gz: Genome assembly: masked with lowercase
```
### Calculate the CHECKSUMs <a name="checksums"></a>
```
  ${DATASTORESPEC_SCRIPTS}/mdsum-folder.bash /path/to/datastore/collection
```
### Move the collection from private to annex for review
Move the directory from private to the annex, e.g.
```
  DIR=MY_NEW_DIRECTORY
  mv /project/legume_project/datastore/private/Glycine/max/$DIR /project/legume_project/datastore/annex/Glycine/max/$DIR
```
Also, note the change in the status file in the private/Genus/species/ dir, e.g.
```bash
  echo $'\n'"Moved Wm82.gnm2.met1.K8RT to v2 on 2018-04-19 by YOUR NAME"$'\n' \
    >> private/Glycine/max/status.glyma.txt
```

## Procedure for adding genome and annotation collections with ds_souschef <a name="using-souschef"></a>
The **ds_souschef.pl** script, in datastore-specifications/scripts/, uses information in a configuration file
to transform provided genome assembly and annotation files into collections that follow datastore conventions.
Examples of configuration files are available at scripts/ds_souschef_configs/. In fact, the best practice is
to store configuration files in that directory, for each new assembly+annotation collection set. There is one
configuration file, in yaml format, for each assembly+annotation pair to be processed by ds_souschef.pl.

The instructions below use the example of *Arabidopsis thaliana* (included in the datastore for its general
utility as a plant biology model species). The data set in this example came from Phytozome prior to conversion to the
LIS datastore formats, and originated ultimately from the Arabidopsis Genome Initiative, TAIR, and Araport projects.
The ds_souschef.pl tool can be applied to datasets from other sources, but the particular information in the
configuration file will depend on the files to be transformed. Files from the Pnytozome repository have their own conventions
and patterns, reflected in this Arabidopsis example.

NOTE: Also see additional instructions and notes for preparation of many collections 
at [ds_souschef_prep_examples](https://github.com/legumeinfo/datastore-specifications/tree/main/PROTOCOLS/ds_souschef_prep_examples)

### Download assembly and annotation into working directory:
```bash
  cd /project/legume_project/datastore/private/Arabidopsis/thaliana
```
The directory layout for Phytozome assembly and annotation files (for this example) is:
```bash
  Athaliana_447_Araport11/annotation
  Athaliana_447_Araport11/assembly
  Athaliana_447_Araport11/Athaliana_447_Araport11.readme.txt
```
### Examine the IDs in the annotations
In the case of the JGI/Araport11 annotations, the GFF has ID suffixes like
  AT1G01020.Araport11.447
... but the fasta sequences (cds, protein, transcript) do not. So, do some pre-processing
to get a GFF that will be compatible with the fata annotations:
```
  zcat Athaliana_447_Araport11/annotation/Athaliana_447_Araport11.gene.gff3.gz |
    perl -pe 's/\.Araport11\.447//g' |
    bgzip -c > Athaliana_447_Araport11/annotation/Athaliana_447_Araport11.gene.no_suffix.gff3.gz

  zcat Athaliana_447_Araport11/annotation/Athaliana_447_Araport11.gene_exons.gff3.gz |
    perl -pe 's/\.Araport11\.447//g' |
    bgzip -c > Athaliana_447_Araport11/annotation/Athaliana_447_Araport11.gene_exons.no_suffix.gff3.gz
```
### Register keys
First check status of the local instance of the registry.
Clone it if you don't have it already):
```bash
  git clone https://github.com/legumeinfo/datastore-registry.git
  cd datastore-registry
  ./register_key.pl -value "Arabidopsis thaliana genomes Col0.gnm9"
  ./register_key.pl -value "Arabidopsis thaliana annotations Col0.gnm9.ann11"
  git add ds_registry.tsv
  git commit -m "Add keys for Xxx xxx assembly and annotations"
  git push
```
### Prepare a config file
Set up a config file at /project/legume_project/datastore/datastore-specifications/scripts/ds_souschef_configs
Base it on a config file for another Phytozome collection.
```bash
  vim conf_arath.Col0.gnm9.yml
```
### Copy the Phytozome readme file into the annotation and assembly directories so ds_souschef can find it in those locations:
```bash
  cp Athaliana_447_Araport11/Athaliana_447_Araport11.readme.txt Athaliana_447_Araport11/annotation/
  cp Athaliana_447_Araport11/Athaliana_447_Araport11.readme.txt Athaliana_447_Araport11/assembly/
```
### Run ds_souschef.pl
The **ds_souschef.pl** program can be run from anywhere, but it is convenient to run it from the configs directory.
Output goes to the working directory specified in the config file.
```bash
  cd /project/legume_project/datastore//datastore-specifications/scripts/ds_souschef_configs/
  ../ds_souschef.pl -config conf_arath.Col0.gnm9.yml
```
### Check the results
Check the new collections in the working directory, in annotations/ and genomes/
Check that all files have non-zero size, that features have the correct prefixing, etc.
Check for UNDEFINED in the annotation files; this indicates a problem in the hashing.

### Compress and index
```bash
  cd /project/legume_project/datastore/private/GENUS/SPECIES
  compress_and_index.sh genomes/COLLECTION
  compress_and_index.sh annotations/COLLECTION
```
### Validate the README files
```bash
  validate.sh readme genomes/COLLECTION/README*yml
  validate.sh readme annotations/COLLECTION/README*yml
```
### Calculate the CHECKSUMs 
```
  ${DATASTORESPEC_SCRIPTS}/mdsum-folder.bash /path/to/datastore/collection
```
### Move the collections into place in the annex for review
```bash
  cd /project/legume_project/datastore/annex/Genus/species
  mv annotations/COLLECTION  /project/legume_project/datastore/annex/Genus/species/annotations/
  mv genomes/COLLECTION  /project/legume_project/datastore/annex/Genus/species/genomes/
```

## Questions and handling hard cases with ds_souschef <a name="souschef-faq"/>
How to convert GenBank molecule accession names into chromosome names? 
Do this by creating a hash file of accessions and chromosome IDs,
and pass into ds_souschef using the -SHash flag. Here is an example, using Bauhinia variegata.
First create the hash file:
```bash
  zcat $GFF | awk -v FS="\t" '$3~/region/ && $1~/CM/ {print $9}' |
    perl -pe 's/.+ann1\.([^:]+):.+;chromosome=(\d+);.+/$1\t$2/' |
    awk '{printf("%s\tChr%02d\n", $1, $2)}' |
      cat > "GCA_022379115.2/initial_chr_map.tsv"

    # looks like:
    #   CM039426.1  Chr01
    #   CM039427.1  Chr02
```

Then call ds_souschef:
```bash
  SHASH="$WD/GCA_022379115.2/initial_chr_map.tsv"
  ds_souschef.pl -conf conf_bauva.BV-YZ2020.gnm2.ann1.yml -SHash $SHASH
```

How to modify the gene/feature IDs? The hashed (new) gene ID can be reshaped somewhat with the use of 
a "strip" pattern in the from_to_gff section of the config. For example, the following in that section of
the config file will strip those characters from GenBank feature IDs:
```bash
  strip: 'gnl|WGS:JAKRYI|' 
```

For very complex transformations, you may need to first generate the featid_map.tsv and/or seqid_map.tsv
with an initial run of ds_souschef, then modify the values in the second field to the form that you want, 
then re-run ds_souschef, specifying the map files with -seqid_map and/or -featid_map as appropriate.

## Initiate or update "about_this_collection.yml" <a name="description-genus-species"/>
Each GENUS and species directory has an about_this_collection subdirectory, each containing
a single "description" file, like so (for Vigna):
```
  angularis/about_this_collection/description_Vigna_angularis.yml
  GENUS/about_this_collection/description_Vigna.yml
  radiata/about_this_collection/description_Vigna_radiata.yml
  unguiculata/about_this_collection/description_Vigna_unguiculata.yml
```
It is important to update these files when new genome and annotation resources are added, as these files are 
used for Intermine creation and for generating several core Jekyll pages:
"taxa" (LIS), "resources" (SoyBase), "collections", and "tools" (both LIS and SoyBase).
See the about\_this\_collection specifications for GENUS [here](https://github.com/legumeinfo/datastore-specifications/tree/main/Genus/GENUS/about_this_collection)
and for species [here](https://github.com/legumeinfo/datastore-specifications/tree/main/Genus/species/about_this_collection).

## Calculate AHRD functional annotations <a name="calc-ahrd"/>
(TBD)

## Calculate gene family assignments (GFA) <a name="calc-gfa"/>
(TBD)

## Add to pan-gene set <a name="pan-genes"/>
(TBD)

## Load relevant mine <a name="mine-loading"/>
(TBD)

## Add BLAST targets <a name="blast-targets"/>
The main [legumeinfo sequenceserver instance](https://sequenceserver.legumeinfo.org) is built using a dedicated [Dockerfile](https://github.com/legumeinfo/sequenceserver/blob/lis/db/Dockerfile) maintained on the branch lis. After modifying the file with respect to new BLAST targets, you must commit your changes, add a tag (e.g. git tag v2022.12.21), and git push --tags which will trigger a [github actions workflow](https://github.com/legumeinfo/sequenceserver/actions/workflows/deploy.yml) to rebuild and deploy to the production server. 

## Incorporate into GCV <a name="populate-gcv"/>
(TBD)

## Update the jekyll collections listing <a name="update-jekyll"/>
(TBD)

## Update browser configs <a name="update-browsers"/>
(TBD)
