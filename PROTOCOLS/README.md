# General protocols: procedures for adding new data, etc.
Instructions for adding data to the Data Store. General protocols.

## PROCEDURE FOR ADDING A NEW DATA SET TO THE DATA STORE

NOTE: The instructions below are for curators working on any instance of
LegFed Data Store - at e.g. soybase.org, peanutbase.org, legumeinfo.org etc. 
If you are a researcher or user of and you have a data set that you would like
to contribute, PLEASE <a href="https://legumeinfo.org/contact">CONTACT US!</a> 
We would love to work with you. You are welcome to use the templates in this 
directory and begin preparing your data for submission, but the final uploading
will need to be done by curators with the affiliated database projects.


### Upload the data to the local Data Store file system
The data store is accessible via command line from several servers.
As of summer, 2021, any of these servers can be used:
  - lis-stage.usda.iastate.edu 
  - soybase-stage.usda.iastate.edu 
  - legumefederation.usda.iastate.edu 
  - peanutbase-stage.usda.iastate.edu

Upload (scp) data to the private directory (and appropriate subdirectory) here:
  /usr/local/www/data/private/
  e.g.
  /usr/local/www/data/private/Glycine/max

### Name the directories and files
Apply directory names, following the patterns described in specifications in this repository. 

Each data "collection," consisting of one or more related data files of a particular type (genome assembly, 
annotation, marker set, etc.) has a name consisting of three dot-separated parts or fields (four fields for annotation collections):
genotype.data-type.key-name

For annotation, genome, and synteny collections, the "key-name" is a four-letter string, "checked out" from 
this registry: http://bit.ly/LegFed_registry
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
Note the -r flag for the md5 command.
```
  KEY=K8RT
  rm CHECKSUM*
  md5 -r * > CHECKSUM.$KEY.md5
```

### Move the collection from v2 to private
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

