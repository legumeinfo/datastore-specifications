# General protocols: procedures for adding new data, etc.
Instructions for adding data to the Data Store and then updating associated LIS/SoyBase/PeanutBase resources.

## Table of Contents
[General procedure for adding a new data set to the data store](#adding-to-the-datastore) <br>
[Procedure for adding genome and annotation collections with ds_souschef](#using-souschef) <br>
[Initiate or update "about_this_collection.yml"](#description-genus-species) <br>
[Calculate AHRD functional annotations](#calc-ahrd) <br>
[Calculate gene family assignments (GFA)](#calc-gfa) <br>
[Add to pan-gene set](#pan-genes) <br>
[Load relevant mine](#mine-loading) <br>
[Add BLAST targets](#blast-targets) <br>
[Incorporate into GCV](#populate-gcv) <br>
[Update the jekyll collections listing](#update-jekyll) <br>
[Update browser configs](#update-browsers) <br>

## General procedure for adding a new data set to the data store <a name="adding-to-the-datastore"/>

NOTE: The instructions below are for curators working on files used by
legumeinfo.org, soybase.org, and peanutbase.org.
If you are a researcher or user of and you have a data set that you would like
to contribute, please <a href="https://legumeinfo.org/contact">CONTACT US!</a>
We would love to work with you.

#### Upload the data to the local Data Store file system
The data store is accessible via command line from several servers.
As of summer, 2021, any of these servers can be used:
  - lis-stage.usda.iastate.edu
  - soybase-stage.usda.iastate.edu
  - legumefederation.usda.iastate.edu
  - peanutbase-stage.usda.iastate.edu

Upload (scp) data to the private directory (and appropriate subdirectory), e.g. /usr/local/www/data/private/Glycine/max

#### Name the directories and files
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
#### Fill out the README and MANIFEST files
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
#### Calculate the CHECKSUMs <a name="checksums"></a>
```
  ${DATASTORESPEC_SCRIPTS}/mdsum-folder.bash /path/to/datastore/collection
```
#### Move the collection from v2 to private
Move the directory from from v2 to private, e.g.
```
  DIR=MY_NEW_DIRECTORY
  mv /usr/local/www/data/private/Glycine/max/$DIR /usr/local/www/data/v2/Glycine/max/$DIR
```
Also, note the change in the status file in the private/Genus/species/ dir, e.g.
```
  echo $'\n'"Moved Wm82.gnm2.met1.K8RT to v2 on 2018-04-19 by YOUR NAME"$'\n' \
    >> private/Glycine/max/status.glyma.txt
```

## Procedure for adding genome and annotation collections with ds_souschef <a name="using-souschef"></a>
The **ds_souschef.pl** script, in datastore-specifications/scripts/, uses information in a configuration file
to transform provided genome assembly and annotation files into collections that follow Data Store conventions.
Examples of configuration files are available at scripts/ds_souschef_configs/. In fact, the best practice is
to store configuration files in that directory, for each new assembly+annotation collection set. There is one
configuration file, in yaml format, for each assembly+annotation pair to be processed by ds_souschef.pl.

The instructions below use the example of *Arabidopsis thaliana* (included in the Data Store for its general
utility as a plant biology model species). The data set in this example came from Phytozome prior to conversion to the
LIS Data Store formats, and originated ultimately from the Arabidopsis Genome Initiative, TAIR, and Araport projects.
The ds_souschef.pl tool can be applied to datasets from other sources, but the particular information in the
configuration file will depend on the files to be transformed. Files from the Pnytozome repository have their own conventions
and patterns, reflected in this Arabidopsis example.

#### Download assembly and annotation into working directory at lis-stage:
```
  cd /usr/local/www/data/private/Arabidopsis/thaliana
```
The directory layout for Phytozome assembly and annotation files (for this example) is:
```
  Athaliana_447_Araport11/annotation
  Athaliana_447_Araport11/assembly
  Athaliana_447_Araport11/Athaliana_447_Araport11.readme.txt
```
#### Examine the IDs in the annotations
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
#### Register keys
First check status of the local instance of the registry.
Clone it if you don't have it already):
```
  git clone https://github.com/legumeinfo/datastore-registry.git
  cd datastore-registry
  ./register_key.pl -value "Arabidopsis thaliana genomes Col0.gnm9"
  ./register_key.pl -value "Arabidopsis thaliana annotations Col0.gnm9.ann11"
  git add ds_registry.tsv
  git commit -m "Add keys for Xxx xxx assembly and annotations"
  git push
```
#### Prepare a config file
Set up a config file at /usr/local/www/data/datastore-specifications/scripts/ds_souschef_configs
Base it on a config file for another Phytozome collection.
```
  vim conf_arath.Col0.gnm9.yml
```
#### Copy the Phytozome readme file into the annotation and assembly directories so ds_souschef can find it in those locations:
```
  cp Athaliana_447_Araport11/Athaliana_447_Araport11.readme.txt Athaliana_447_Araport11/annotation/
  cp Athaliana_447_Araport11/Athaliana_447_Araport11.readme.txt Athaliana_447_Araport11/assembly/
```
#### Run ds_souschef.pl
The **ds_souschef.pl** program can be run from anywhere, but it is convenient to run it from the configs directory.
Output goes to the working directory specified in the config file.
```
  cd /usr/local/www/data/datastore-specifications/scripts/ds_souschef_configs/
  ../ds_souschef.pl -config conf_arath.Col0.gnm9.yml
```
#### Check the results
Check the new collections in the working directory, in annotations/ and genomes/
Check that all files have non-zero size, that features have the correct prefixing, etc.
Check for UNDEFINED in the annotation files; this indicates a problem in the hashing.

#### Compress and index
```
  cd /usr/local/www/data/private/GENUS/SPECIES
  compress_and_index.sh genomes/COLLECTION
  compress_and_index.sh annotations/COLLECTION
```
#### Validate the README files
```
  validate.sh readme genomes/COLLECTION/README*yml
  validate.sh readme annotations/COLLECTION/README*yml
```
#### Calculate the CHECKSUMs 
```
  ${DATASTORESPEC_SCRIPTS}/mdsum-folder.bash /path/to/datastore/collection
```
#### Move the collections into place in data/v2/
```
  cd /usr/local/www/data/v2/Genus/species
  mv annotations/COLLECTION  /usr/local/www/data/v2/Genus/species/annotations/
  mv genomes/COLLECTION  /usr/local/www/data/v2/Genus/species/genomes/
```

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
