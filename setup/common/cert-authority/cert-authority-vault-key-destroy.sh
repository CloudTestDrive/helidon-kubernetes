
SCRIPT_NAME=`basename $0`
export CA_SETTINGS=cert-authority-settings.sh

if [ -f $CA_SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing CA settings information"
    source $CA_SETTINGS
  else 
    echo "$SCRIPT_NAME No existing CA settings cannot continue"
    exit 11
fi

cd ../vault
# the initials will be handled for us
bash ./vault-key-destroy.sh $CERT_VAULT_KEY_NAME

RESP=$?
if [ $RESP -ne 0 ]
then
  echo "Vault-key-destroy on key $CERT_VAULT_KEY_NAME returned an error, unable to continue"
  exit $RESP
fi