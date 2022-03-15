#!/bin/bash -f
sourcefile=$1
destfile=$2
oldtext=$3
newtext=$4
echo "Templating $sourcefile replacing $oldtext with $newtext to destination $destfile"
#echo command is "s/$oldtext/$newtext/"
cat $sourcefile | sed -e "s/$oldtext/$newtext/" > $destfile