#!/bin/bash -f
export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
then
  echo "Loading existing settings"
  source $SETTINGS
else
  echo "Creating new settings information"
fi
if [ -z "$USER_INITIALS_REUSED" ]
then
  echo "No reuse info for initials, will try to remove anyway"
  USER_INITIALS_REUSED=false
fi

if [ "$USER_INITIALS_REUSED" = false ]
then
  echo "Removing saved initials"
  bash ./delete-from-saved-settings.sh USER_INITIALS
  bash ./delete-from-saved-settings.sh USER_INITIALS_REUSED
else
  echo "Initials are reused, not removing"
fi