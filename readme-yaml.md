# README YAML files

Every file-containing directory, AKA "collection", in the LIS datastore should contain a README file in YAML format.

Filename: README.*collection*.yml

Examples:
- `README.IT97K-499-35.gnm1.QnBW.yml`
- `README.IT97K-499-35.gnm1.ann1.zb5D.yml`
- `README.CB27_x_IT82E-18.gen.Pottorff_Li_2014.yml`

## Content
The README content is given in the official template here:

https://legumeinfo.org/data/about_the_data_store/templates/template__README.collection_name.yml

READMEs must be YAML-compliant, which means they pass the test on

http://www.yamllint.com/ 

## Requirements
- When in doubt, enclose values in quotes.
- `identifier` at the top repeats the name of the collection.
- `synopsis` should be short, 100 characters or so.
- DOIs are DOIs, not URLs (e.g. 10.1534/g3.118.200521)
- The date format is 2020-03-23.
- Missing data should be left blank; do not use "N/A" or "none" or anything else.
- genotype is a YAML array; use the format strain1 x strain2 for bi-parental crosses.
- Do not use a colon within the value unless you enclose the entire value in quotes.

Do not add any attributes without consulting Sam -- additional attributes will break the InterMine README parser (until Sam adds them).
