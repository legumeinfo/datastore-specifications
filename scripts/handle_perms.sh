#!/usr/bin/env sh
# NAME
#     handle_perms.sh - list/fix datastore files/dirs with invalid permissions/ownership
#
# SYNOPSIS
#     handle_perms.sh [-l|-f] PATH
#
# DESCRIPTION
#     Recursively list/fix files/directories rooted at PATH that find that meet at
#     least one of the following criteria:
#     1. Have incorrect group ownership,
#     2. Don't have user/group read/write permissions, or
#     3. (directories) aren't user/group searchable or don't have the setgid bit set
#
# OPTIONS
#     -l    Produce a detailed listing (ls -ld) of each output file/directory
#     -f    apply fixes to the subset of files owned by the user running the script

set -o errexit -o nounset

if [ ${#} -eq 0 ] || [ ${#} -gt 2 ]
then
  echo "usage: handle_perms.sh [-l|-f] PATH" 1>&2
  exit 1
fi

case ${1} in
  -l) action_d='-exec ls -ld {} +'
      action_f='-exec ls -ld {} +'
      path=${2} ;;
  -f) user="-user $(id -un)"
      action_d='-exec chmod u+rwx,g+rwxs,o+rx {} +'	  
      action_f='-exec chmod u+rw,g+rw,o+r {} +'	  
      path=${2} ;;
   *) path=${1} ;;
esac

#first pass for directories
find "${path}" ${user:-} -type d \
   \( \
    ! -group proj-legume_project -o \
    ! \( -perm -ug+rwx -a -perm -g+s -a -perm -o+rx \) \
   \) \
  ${action_d:-} 

#second pass for regular files
find "${path}" ${user:-} -type f \
   \( \
    ! -group proj-legume_project -o \
    ! \( -perm -ug+rw -a -perm -o+r \) \
   \) \
  ${action_f:-} 
