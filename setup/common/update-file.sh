#!/bin/bash -f
UPDATE_FILE=$1
OLD_TEXT=$2
NEW_TEXT=$3
if [ $# -gt 3 ]
then
  SED_SEP=$4
else
  SED_SEP=/
fi
echo "Updating $UPDATE_FILE replacing $OLD_TEXT with $NEW_TEXT using separator $SED_SEP"
TEMP_FILE="$UPDATE_FILE".tmp
SED_CMD="s""$SED_SEP""$OLD_TEXT""$SED_SEP""$NEW_TEXT""$SED_SEP""g"
#echo "Sed command is :""$SED_CMD"
cat $UPDATE_FILE | sed -e "$SED_CMD" > $TEMP_FILE
rm $UPDATE_FILE
mv $TEMP_FILE $UPDATE_FILE