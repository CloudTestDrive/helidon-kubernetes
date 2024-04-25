#!/bin/bash -f

SCRIPT_NAME=`basename $0`

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f "$SETTINGS" ]
then
    echo "Existing settings file located, loading it"
    source $SETTINGS
fi

if [ -z "$SMALLSTEP_DIR" ]
then
    echo "Smallstep has not been setup by these scripts, continuing"
else
    echo "Smallstep has already been setup by these scripts, exiting"
    exit 0
fi

SMALLSTEP_DIR=$HOME/smallstep

if [ -d $SMALLSTEP_DIR ]
  then 
    echo "Step instalation directory $SMALLSTEP_DIR already exists, will not overwrite or destroy this directory"
    echo "The script will stop, please move or manually destroy (if no longer needed) the $SMALLSTEP_DIR directory."
  else
     echo "$SMALLSTEP_DIR does not exist creating"
     mkdir -p $SMALLSTEP_DIR
fi


cd $SMALLSTEP_DIR

echo "Locating download page for latest version of step and removing whitespace"
LATEST_STEP_URL=`curl -i -s https://github.com/smallstep/cli/releases/latest | grep -i location: | awk '{print $2}'  | sed -e 's/[\r]//g' | tr -d '\n'`
echo "Latest version location page is $LATEST_STEP_URL"
echo "Identifying latest Version of step download link"
STEP_LATEST_DOWNLOAD=`curl -i -s -X GET $LATEST_STEP_URL | grep dl.step.sm | grep step_linux | grep amd64.tar.gz | xmllint  --xpath 'string(/li/a/@href)' -`
echo "Latest step download location is $STEP_LATEST_DOWNLOAD"
echo "Downloading step"
wget -O step.tar.gz $STEP_LATEST_DOWNLOAD
RESP=$?
if [ "$RESP" -eq 0 ]
then
  echo "Downloaded step"
else
  STEP_LATEST_DOWNLOAD=https://dl.smallstep.com/gh-release/cli/gh-release-header/v0.26.0/step_linux_0.26.0_amd64.tar.gz 
  echo "Problem downloading step, going to use a fallback of $STEP_LATEST_DOWNLOAD"
  wget -O step.tar.gz $STEP_LATEST_DOWNLOAD
  RESP=$?
  if [ "$RESP" -eq 0 ]
  then
    echo "Downloaded step from fallback"
  else
    echo "Unable to download step, cannot continue"
    exit $RESP
  fi
fi
echo "Extrating step to temp location"
tar -xf step.tar.gz
echo "Removing download file"
rm step.tar.gz
echo "Moving step into place"
mv step_*/bin/step .
echo "Making executable"
chmod +x step
echo "Removing unneeded temp location"
rm -rf step_*

echo "Root certificate setup"
if [ -x $SMALLSTEP_DIR/step ]
then
    if [ -f $SMALLSTEP_DIR/root.crt ] 
    then
        echo "Root certificate already exists, not creating"
    else
        echo "Creating root certificate"
        $SMALLSTEP_DIR/step certificate create root.cluster.local $SMALLSTEP_DIR/root.crt $SMALLSTEP_DIR/root.key --profile root-ca --no-password --insecure --kty=RSA
    fi
else
    echo "Step command does not exist or is not executable, other scripts may fail, Root certificate already exists you may be able to reuse it"
    exit -1
fi 
echo "SMALLSTEP_DIR=$SMALLSTEP_DIR" >> $SETTINGS