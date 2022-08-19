#!/bin/bash -f
SCRIPT_NAME=`basename $0`
if [ $# -lt 4 ]
then
  echo "SCRIPT_NAME missing required arguments"
  echo "  1st arg Name of the source file to modify - can be relative to the current directory or absolute"
  echo "  2nd ard Name of the destination file - can be relative to the current directory or absolute"
  echo "  3rd arg origional text to substitute"
  echo "  4th arg substiture test"
  echo "Optional"
  echo "  5th arg the character to use in the sed command as separator, defaults to /"
  exit 1
fi
SOURCE_FILE=$1
DEST_FILE=$2
OLD_TEXT=$3
NEW_TEXT=$4
if [ $# -ge 5 ]
then
  SED_SEP=$5
else
  SED_SEP=/
fi
echo "Templating $SOURCE_FILE replacing $OLD_TEXT with $NEW_TEXT into destination $DEST_FILE using separator $SED_SEP"
SED_CMD="s""$SED_SEP""$OLD_TEXT""$SED_SEP""$NEW_TEXT""$SED_SEP""g"
#echo command is "$SED_CMD"
cat $SOURCE_FILE | sed -e "$SED_CMD" > $DEST_FILE