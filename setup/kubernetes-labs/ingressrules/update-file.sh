#!/bin/bash -f
updatefile=$1
oldtext=$2
newtext=$3
echo Updating $updatefile replacing $oldtext with $newtext 
temp="$updatefile".tmp
#echo command is "s/store.$oldtext.nip.io/store.$newtext.nip.io/"
cat $updatefile | sed -e "s/store.$oldtext.nip.io/store.$newtext.nip.io/" > $temp
rm $updatefile
mv $temp $updatefile