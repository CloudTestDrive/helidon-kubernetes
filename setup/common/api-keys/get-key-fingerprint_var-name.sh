#!/bin/bash -f
KEY_NAME=$1
USER_INITIALS=$2

echo `bash ../settings/to-valid-name.sh "$KEY_NAME"_API_KEY_FINGERPRINT_"$USER_INITIALS"`