#!/bin/bash -f
SOURCE_FILE=$1
DEST_FILE=$2
OLD_TEXT=$3
NEW_TEXT=$4
echo "Templating $SOURCE_FILE replacing $OLD_TEXT with $NEW_TEXT into destination $DEST_FILE"
#echo command is "s/$OLD_TEXT/$NEW_TEXT/"
cat $SOURCE_FILE | sed -e "s/$OLD_TEXT/$NEW_TEXT/" > $DEST_FILE