# about_this_collection

Overall information about a species collection is contained in this directory; there are no subdirectories.

Files:
- _description_Genus_species_.yml

### Description and details about description_Genus_species.yml file

This file contains information about the (1) Genus species (gensp), (2) resources (tools) available for the gensp and (3) information about each strain with the gensp. The information present in this file are used to populate the information on the Genomics tabs at [SoyBase](https://www.soybase.org/resources/), [LegumeInfo](https://www.legumeinfo.org/genomics/), and [PeanutBase](https://www.peanutbase.org/genomics/), and for loading the respective InterMine instances, and for populating some tool pages -- notably, the [SoyBase page of genome browsers](https://www.soybase.org/tools/browsers/). Thus, it is important that this data is up-to-date and correctly formatted.

```
---
taxid: <NCBI taxon ID>
genus: <Genus>
species: <species>
abbrev: <gensp>
commonName: <common name>
description: <"Detailed description of the Genus species">
resources:
  - name: <Name of tool>
    URL: <"URL of tool">
    description: <"Description of the tool">
strains:
  - identifier: <genotype ID used in the collection. Example Wm82>
    accession: <ID used in germplasm repository (PI number) or GenBank accession ID. If neither are present, refer to the source publication for accession ID.>
    name: <Full name of the genotype/strain/cultivar. Example Williams 82>
    accession_group: <OPTIONAL FIELD. Name of reference genome or citation from a large study, e.g. "Williams 82" or "Liu, Du et al., 2020". 
                      This text is used as a title under which genomes may be grouped in the resources and collections pages.>
    origin: <Country or location of origin>
    description: <"A one-line description of the genome or resource, informative to users. This text is used at the resources and collections pages."> 
```
##### Please see the [example](description_Genus_species.yml) file
