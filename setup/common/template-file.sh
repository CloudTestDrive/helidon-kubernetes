#!/bin/bash -f
updatefile=$1
destfile=$2
oldtext=$3
newtext=$4
echo Templating $updatefile replacing $oldtext with $newtext to destination $destfile
#echo command is "s/$oldtext/$newtext/"
cat $updatefile | sed -e "s/$oldtext/$newtext/" > $destfile