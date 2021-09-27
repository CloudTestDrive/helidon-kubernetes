#!/bin/bash -f
echo Updating $1 replacing $2 with $3 
updatefile=$1
temp="$config".tmp
#echo command is "s/store.$2.nip.io/store.$3.nip.io/"
cat $updatefile | sed -e "s/store.$2.nip.io/store.$3.nip.io/" > $temp
rm $updatefile
mv $temp $updatefile