#!/usr/bin/env sh
# NAME
#     fixbad.sh - fix datastore files/dirs with invalid permissions/ownership
#
# SYNOPSIS
#     fixbad.sh PATH
#
# DESCRIPTION
#     Recursively fix permissions & group ownership of files/directories rooted
#     at PATH (that are owned by the user executing the script) to meet all of
#     the following criteria:
#
#     1. Correct group ownership,
#     2. User/group read/write permission,
#     3. (directories) user/group searchable,
#     4. (directories) setgid bit set

set -o errexit -o nounset

find "$1" -user $(id -un) \( \
  \( -type d \( \
       \( ! -perm -ug+rwx -exec chmod ug+rwx {} + \) -o \
       \( ! -perm -g+s -exec chmod g+s {} + \) \
     \) \
  \) -o \
  \( -type f ! -perm -ug+rw -exec chmod ug+rw {} + \) -o \
  \( ! -group proj-legume_project -exec chgrp proj-legume_project {} + \) \
\)
