#!/bin/sh
# SYNOPSIS
#     validate.sh SCHEMA_PREFIX YAML_FILE
#
# DESCRIPTION
#     wrapper for https://github.com/legumeinfo/datastore-specifications/blob/main/validate
#
# EXAMPLES
#     validate.sh readme README.collection.yml

set -o nounset -o errexit

readonly datastore_specifications=/usr/local/www/data/datastore-specifications

if [ $# -ne 2 ] || [ ! -f ${datastore_specifications}/"${1}.schema.json" ]
then
  echo "usage:"
  for json_schema in ${datastore_specifications}/*.schema.json
  do
    printf '    validate.sh %-25s YAML_FILE\n' "$(basename ${json_schema} .schema.json)"
  done
  exit 1
fi

${datastore_specifications}/validate ${datastore_specifications}/"${1}.schema.json" "${2}"