# about_this_collection

Overall information about a species collection is contained in this directory; there are no subdirectories.

Files:
- _description_Genus_species_.yml

### Description and details about description_Genus_species.yml file

This file contains information about the (1) Genus species (gensp), (2) resources (tools) available for the gensp and (3) information about each strain with the gensp. The information present in this file are used to populate the information on the [SoyBase Genomics](https://www.soybase.org/resources/) page.

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
    accession_group: <Listed a reference genome or from a large study. This text is used in the resources and collections pages.>
    origin: <Country or location of origin>
    description: <"A breif sentence informative to users. This text is used at the resources and collections pages. Example: versions or identifiers."> 
```
##### Please review the [example](description_Genus_species.yml) file
