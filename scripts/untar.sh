#!/bin/bash
start=$( pwd )
for tar in $( ls $1/*.tar.gz); do
    id=$( echo $tar | sed "s/$1\///" | sed "s/.tar.gz//")
    mkdir -p $1/$id && cd $1/$id
    tar -zxf ../$id.tar.gz
    cd $start
done
