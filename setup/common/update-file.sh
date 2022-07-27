#!/bin/bash -f
updatefile=$1
oldtext=$2
newtext=$3
if [ $# -gt 3 ]
then
  SED_SEP=$4
else
  SED_SEP=/
fi
echo "Updating $updatefile replacing $oldtext with $newtext using separator $SED_SEP"
temp="$updatefile".tmp
SED_CMD="s""$SED_SEP""$oldtext""$SED_SEP""$newtext""$SED_SEP""g"
#echo "Sed command is :""$SED_CMD"
cat $updatefile | sed -e "$SED_CMD" > $temp
rm $updatefile
mv $temp $updatefile