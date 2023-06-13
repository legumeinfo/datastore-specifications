# Protocols for adding gene function information to the gene_functions collections.

## Table of Contents
[General approach, philosophy, and objectives](#general) <br>
[File and path specifications](#files_and_paths) <br>
[Workflows](#workflows) <br>
[Accessing manuscripts](#manuscripts) <br>
[Requirements](#requirements) <br>
[Representing traits using ontologies](#ontologies) <br>
[Working on gene function documents in GitHub](#github_work) <br>


## General approach, philosophy, and objectives <a name="general"/>

While all genes in a genome presumably have functions, many of those functions are either vital such that mutations are lethal or detrimental; or cryptic due to redundancy or activation in unusual environmental or developmental conditions. It may be that a relatively small number of genes have clear causal relationships with traits of agronomic interest -- genes for which natural variation has been selected upon during crop domestication and improvement. Such genes would include modifiers of flowering time, seed size or color or shape, plant architecture, disease resistance, reduction of dormancy, loss of pod shatter, etc. These types of genes are the ones that are the focus of gene-function curation in the Data Store.

The focus is genes for which phenotypes have been observed for known mutants. In general, reports that are simply bioinformatic characterizations of gene families should be AVOIDED for the purpose of the gene-function collections here - as should other high-throughput experiments that report expression responses, gene interaction networks, etc.

The curation approach has been designed to be relatively efficient and non-cumbersome for the curator - in the sense that limited information is required, and some portions of the process are aided by scripts.

## File and path specifications <a name="files_and_paths"/>
The file and directory-path specifications are given in the README file in two locations: [datastore-specifications](https://github.com/legumeinfo/datastore-specifications/tree/main/Genus/species/gene_functions) and [gene-function-registry](https://github.com/legumeinfo/gene-function-registry).

The files will be prepared and reviewed away from the main Data Store, in the gene-function-registry. Specifications and protocols (this document) are in datastore-specifications. After review and revision if needed, new gene records (as yaml documents) will be added to the appropriate gensp.traits.yml file in the Data Store. Draft curation work will go into the [gene-function-registry](https://github.com/legumeinfo/gene-function-registry) repository, and then go into the Data Store file system -- and from there, into the [datastore-metadata](https://github.com/legumeinfo/datastore-metadata) repository.

## Workflows <a name="workflows"/>
Since we have several curators, with varying levels of experience, new gene function records (yaml documents) should be reviewed before they are incorporated into the main datastore. The workspace for drafting and reviewing the records is at the [gene-function-registry](https://github.com/legumeinfo/gene-function-registry), with the yaml documents going into the respective Genus/species directories. The work should begin in a curator's "work-in-progress" (wip) directory. For example, here is Steven's Glycine/max [wip directory](https://github.com/legumeinfo/gene-function-registry/tree/main/Glycine/max/wip_steven).

When starting to curate a manuscript, the manuscript should be selected from (or added to) the Google Docs [tracking spreadsheet](https://docs.google.com/spreadsheets/d/1iDdaIQNqK8jvkyQZHATSC1gI-FVhlKv5xde4yPR-Rzs/edit), and then note in the spreadsheet the status, i.e., Steven would note "wip_steven" in the second column (doc status). When ready to review, he would note the date in "to review". The date would be noted when the review is completed, and also when it is incorporated into the datastore.

As we are just working out new curation protocols (as of mid-2023), it is likely that the curation protocol and practices will evolve, as we figure out how to streamline the process and make it more robust. See the current recommended GitHub practices for this repository below.


## Accessing manuscripts <a name="manuscripts"/>
Most publications that we work on will be available in [PubMed](https://pubmed.ncbi.nlm.nih.gov) and [PubMedCentral](https://www.ncbi.nlm.nih.gov/pmc/). Additionally, [PubAg](https://pubag.nal.usda.gov), maintained by the USDA, holds some documents that are not in PubMed or PubMedCentral.

Both the PubMed and PubMedCentral "libraries" are managed by the National Library of Medicine, but they have different characteristics. PubMed holds references to many more manuscripts than PubMedCentral, but only the abstracts. PubMedCentral holds fewer manuscripts, but provides the full text and content of the manuscripts. Thus, PubMed should generally be the starting point when working on a new manuscript. This will link to the full text if available in PubMedCentral - or otherwise in the source journal.

An important tool at PubMed is the "\" Cite" button. This returns a citation (by default, in NLM format, which we will use), that can be copied into the clipboard. This contains the essential information for referencing an article: authors, title, journal, year, DOI, PMID, and PMCID (if available).

An example of an abstract at PubMed is this one: [Ma, Xia, et al., 2019](https://pubmed.ncbi.nlm.nih.gov/30740122/). Note that the PMID is a numeric string (30740122), the PMCID is a numeric string prefixed by PMC (PMC6357947), and the DOI is a dot- and slash-separated string, always beginning "10." (10.3389/fpls.2018.01979).

It is up to the curator how to interact with a publication that they are working on. In some cases, dealing with it online may be sufficient. In other cases, it may be helpful to download it and work on it locally - or to load it into Zotero. This aspect of the curatorial workflow is still to be determined, but will probably vary somewhat by curator's preference - and by consensus of curators who are working together.

## Requirements <a name="requirements"/>
The primary requirements are that the "gensp.traits.yml" files in the datastore be correct and in valid format. The curatorial process leading up to this point may vary, and is not a "requirement" per se. The reason that the ".traits.yml" are crucial is that these will be loaded into InterMine instances, so they are the main source files. The two other files in the gene_functions collections, gensp.citations.txt and gensp.references.txt, are derived programmatically from the gensp.traits.yml files.

Here is a good brief guide to the [yaml format](https://learnxinyminutes.com/docs/yaml/).

Before new yaml records/documents are added to these files (a record or document holding the information about a single gene), they should be checked for valid yaml format - for example, in the [yamllint validator](https://www.yamllint.com). A validator will also be added to the Data Store for this file type (XX to be done).

## Representing traits using ontologies <a name="ontologies"/>
The essence of a trait "record" in our system is the trio of the gene ID, the associated phenotype description, and the supporting reference. A brief informal phenotype description should be entered as the value for phenotype_synopsis, and then formally using ontology terms and accessions in the traits section.The main ontologies we will use are the Plant Ontology (TO), for anatomical terms (root, seed, etc.); and the Plant Trait Ontology (TO), for traits. These can be accessed here: [PO](https://www.ebi.ac.uk/ols4/ontologies/po) and [TO](https://www.ebi.ac.uk/ols4/ontologies/to). Other ontologies may be used if needed; but before going to another ontology, check with one of the senior staff. The advantage to using the broader, more general ontologies where possible is that it is (usually) easier to traverse across different species to find comparable traits if all are using a common few ontologies. When specialize ontologies are needed, they should be added lower in the list under the "traits" section.

The traits block should contain (underneath the "traits" key) one or more entities - both by name and by accession, like this:
```
traits:
  - entity_name: anthocyanin content
    entity: TO:0000071
  - entity_name: leaf
    entity: PO:0025034
  - entity_name: seed
    entity: PO:0009010
```

Note that the dash precedes the entity_name key, and no dash preceds the entity: key. When these two key-value pairs are associated this way, they are linked (as members of an anonymous hash/mapping/dictionary). So: the entity_name of leaf describes the entity of PO:0025034.

## Working on gene function documents in GitHub <a name="github_work"/>

To start, clone the repository (do this once only):
```
    git clone https://github.com/legumeinfo/gene-function-registry.git
```

Change into that directory, and into your work area
```
  cd gene-function-registry/Genus/species/wip_yourname
```

Check out a new branch under your name
```
  git checkout -b yourname
```

Confirm that you're on the new branch
```
  git branch
```

Check the status of your work in your repository
```
  git status
```


Copy the template to start a new yaml document. Though this will eventually be added to a single yaml file that contains multiple yaml "documents" (one per gene or locus), it is probably easier and safer to work on a single isolated yaml file per gene. 

Start work on a selected paper (noting which one you are working on in the "doc status" column
at the [tracking spreadsheet](https://docs.google.com/spreadsheets/d/1iDdaIQNqK8jvkyQZHATSC1gI-FVhlKv5xde4yPR-Rzs/edit#gid=1914121906)).
The temporary/working file should be named in a consistent way (though recognizing that it will be incorporated into the combined document). A good practice is: `Author_Author_Year_Symbol.yml` if possible
... where Symbol is e.g. GmLHY2a  if provided in the paper; otherwise, some one-word name of the trait or
contents, e.g. "height"
```
  cp glyma_work.traits.yml Chen_Dong_2019_GmLHY2a.yml
```

Fill out the yaml document, then check for valid format using [yamllint.com](https://www.yamllint.com).

Periodically as you work check in your changes (to your branch; you can do this without requesting review):
```
  git status
  git add Author_Author_Symbol.yml
  git commit -m "Initial commit of Author_Author_Symbol.yml"
  git push
```

When done, push the file back to the repository (not the datastore proper, but https://github.com/legumeinfo/gene-function-registry.git).
```
    git status
    git add Glycine/max/gene_functions/Chiasson_Loughlin_2014.yml
    git commit -m "Added Glycine max Chiasson_Loughlin_2014 for review."
    git push
```

Update from the remote (not necessary if you have just cloned the repository, but otherwise important practice)
```
  git fetch
  git pull
```

Do some more work, and check it in (add, commit, push).

When you have a yaml document that is ready for review, note that in the
[tracking spreadsheet](https://docs.google.com/spreadsheets/d/1iDdaIQNqK8jvkyQZHATSC1gI-FVhlKv5xde4yPR-Rzs/edit#gid=1914121906))
("to review" column), and then request to merge the change(s) to main.

See an overview of the [merging process here](https://stackabuse.com/git-merge-branch-into-master/).

Merging best practice for a new paper : First checkout main, and update your local copy:
```
  git branch
  git checkout main
  git fetch
  git pull
```

Then merge your branch into main, add a comment about the merge, then push it to the remote:
```
  git merge yourname
```

The merge won't automatically occur, but it will trigger a request for review. After review, the reviewer will either respond with requests for changes, or will approve the merge request.

