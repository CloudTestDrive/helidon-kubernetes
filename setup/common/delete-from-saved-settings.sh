#!/bin/bash -f
export SETTINGS=$HOME/hk8sLabsSettings

texttodelete=$1

if [ -z $texttodeletev ]
then
  echo "Cannot remove blank contents from the settiongs"
  exit 1
fi

TMP_SETTINGS=$SETTINGS.tmp

echo removing $texttodelete from $SETTINGS
cat $SETTINGS | grep -v $texttodelete > $TMP_SETTINGS

rm $SETTINGS
mv $TMP_SETTINGS $SETTINGS