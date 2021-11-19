#!/bin/bash -f
updatefile=$1
oldtext=$2
newtext=$3
echo Updating $updatefile replacing $oldtext with $newtext 
temp="$updatefile".tmp
#echo command is "s/$oldtext/$newtext/"
cat $updatefile | sed -e "s/$oldtext/$newtext/" > $temp
rm $updatefile
mv $temp $updatefile