#!/bin/bash -f
export SETTINGS=$HOME/hk8sLabsSettings

texttodelete=$1

TMP_SETTINGS=$SETTINGS.tmp

echo removing $texttodelete from $SETTINGS
cat $SETTINGS | grep -v $texttodelete > $TMP_SETTINGS

rm $SETTINGS
mv $TMP_SETTINGS $SETTINGS