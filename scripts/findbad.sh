#!/usr/bin/env sh
# NAME
#     findbad.sh - list datastore files/dirs with invalid permissions/ownership
#
# SYNOPSIS
#     findbad.sh [-l] PATH
#
# DESCRIPTION
#     Recursively list files/directories rooted at PATH that find that meet at
#     least one of the following criteria:
#     1. Have incorrect group ownership,
#     2. Don't have user/group read/write permissions, or
#     3. (directories) aren't user/group searchable or don't have the setgid bit set
#
# OPTIONS
#     -l    Produce a detailed listing (ls -ld) of each output file/directory

set -o errexit -o nounset

if [ ${#} -eq 0 ] || [ ${#} -gt 2 ]
then
  echo "usage: badperm.sh [-l] PATH" 1>&2
  exit 1
fi

case ${1} in
  -l) action='-exec ls -ld {} +'
      path=${2} ;;
   *) path=${1} ;;
esac

find "${path}" \
  \( \
    ! -group proj-legume_project -o \
    \( -type d ! \( -perm -ug+rwx -a -perm -g+s \) \) -o \
    \( -type f ! -perm -ug+rw \) \
  \) ${action:-}
