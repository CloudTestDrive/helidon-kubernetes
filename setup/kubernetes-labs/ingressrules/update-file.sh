#!/bin/bash -f
updatefile=$1
oldtext=$2
newtext=$3
echo Updating $updatefile replacing $oldtext with $newtext 
temp="$updatefile".tmp
#echo command is "s/$oldtext.nip.io/$newtext.nip.io/"
cat $updatefile | sed -e "s/$oldtext.nip.io/$newtext.nip.io/" > $temp
rm $updatefile
mv $temp $updatefile