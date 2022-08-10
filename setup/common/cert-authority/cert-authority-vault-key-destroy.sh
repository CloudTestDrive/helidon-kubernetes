
SCRIPT_NAME=`basename $0`
export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No existing settings cannot continue"
    exit 10
fi
export CA_SETTINGS=cert-authority-settings.sh

if [ -f $CA_SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing CA settings information"
    source $CA_SETTINGS
  else 
    echo "$SCRIPT_NAME No existing CA settings cannot continue"
    exit 11
fi
if [ -z $USER_INITIALS ]
then
  echo "Your initials have not been set, you need to run the initials-setup.sh script before you can run thie script"
  exit 1
fi


if [ -z "$VAULT_OCID" ]
then
  echo "Your vault ocid has not been set, you need to run the vault-setup.sh script before you can run this script"
  exit 1
fi


cd ../vault
VAULT_KEY_NAME="$USER_INITIALS""$CERT_VAULT_KEY_NAME"

bash ./vault-key-destroy.sh $VAULT_KEY_NAME