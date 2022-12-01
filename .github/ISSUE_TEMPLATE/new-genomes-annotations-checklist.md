---
name: New genomes+annotations checklist
about: Checklist of tasks associated with new genome and annotation collections
title: ''
labels: ''
assignees: ''

---

# Main steps for adding new genome and annotation collections

### Genus/species: 

name: New genomes+annotations checklist
description: Checklist of tasks associated with new genome and annotation collections
body:
  - type: input
    id: Genus_species
    attributes:
      label: Genus species
      description: What are the Genus andspecies?
      placeholder: ex. Lens culinaris
  - type: input
    id: collections
    attributes:
      label: collections
      description: What are the collection types and names?
      placeholder: ex. CDC_Redberry.gnm2.7C5P CDC_Redberry.gnm2.ann1.5FB4

- [ ] Add collection(s) to the Data Store
- [ ] Validate the README(s)
- [ ] Update about_this_collection.yml
- [ ] Calculate AHRD functional annotations 
- [ ] Calculate gene family assignments (.gfa) 
- [ ] Add to pan-gene set 
- [ ] Load relevant mine 
- [ ] Add BLAST targets 
- [ ] Incorporate into GCV 
- [ ] Update the jekyll collections listing 
- [ ] Update browser configs
