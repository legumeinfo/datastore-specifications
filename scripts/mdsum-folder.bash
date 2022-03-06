#!/bin/bash
if [[ $# -ne 1 || ! -d $1 ]]; then 
    echo USAGE: $0 /path/to/datastore/folder
    exit 1
fi

path=$1
pushd $path
#get the "collection" name
collection=`basename $path`
md5_name=CHECKSUM.$collection.md5

if [[ -e $md5_name ]]; then rm $md5_name; fi
#FIXME: this will work on LIS using BSD. if anyone else ever uses it, will need to test OS and adjust accordingly I think
#find . -type f -not -name $md5_name | xargs md5 -r > $md5_name
find . -type f -not -name $md5_name -not -name ".nfs*" | xargs busybox md5sum > $md5_name
popd
