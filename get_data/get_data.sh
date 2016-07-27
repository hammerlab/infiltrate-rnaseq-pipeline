#!/bin/bash

set -e; # quit on error

# usage: download $1 to $3/$2, confirm it is good gz archive.
url=$1;
outputfname=$2;
prefix=$3;

mkdir -p $3
mkdir -p $3/download_logs/
curl -o $prefix/$outputfname $url;
gzip -t $prefix/$outputfname;
touch $3/download_logs/$2.success; # hacky way to make sure we know what succeeded
echo 'successful';

# read from all files
# while IFS='' read -r line || [[ -n "$line" ]]; do
#     echo "Text read from file: $line"
# done < "$1"