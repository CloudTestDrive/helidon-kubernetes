#!/bin/bash -f
export SETTINGS=$HOME/hk8sLabsSettings

TEXT_TO_DELETE=$1

if [ -z $TEXT_TO_DELETE ]
then
  echo "Cannot remove blank contents from the settiongs"
  exit 1
fi

TMP_SETTINGS=$SETTINGS.tmp

echo removing $TEXT_TO_DELETE from $SETTINGS
cat $SETTINGS | grep -v $TEXT_TO_DELETE > $TMP_SETTINGS

rm $SETTINGS
mv $TMP_SETTINGS $SETTINGS