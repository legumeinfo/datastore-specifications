#!/bin/sh
##
## Run this script in the root of the datastore-metadata directory to load all READMEs into a mongodb database.
##
## Requires jq (likely available in system distro) and yq (pip3 install yq)

for name in `find -name README.*.yml`
do
    yq . $name | mongoimport --db=lis --collection=readme --mode=upsert --upsertFields=identifier
done
    
