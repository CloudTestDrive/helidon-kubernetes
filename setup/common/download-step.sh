#!/bin/bash -f


KEYS_DIR=$HOME/keys

remove=false
if [ $# -gt 0 ]
  then
    if [ $1 = replace ]
      then
        remove=true
    fi
fi

do_step_install=true
if [ -d $KEYS_DIR ]
  then 
    echo "Step instalation directory $KEYS_DIR already exists"
    if [ $remove = true ]
      then
        echo "Removing $KEYS_DIR and all of its contents"
        rm -rf $KEYS_DIR
        mkdir -p $KEYS_DIR
      else
        echo "Wont remove $KEYS_DIR unless you add a 2nd argument to this script with a value of replace"
        echo "Will skip download of step and attempt to continue using existing step setup"
        do_step_install=false
    fi   
  else
     echo "$KEYS_DIR does not exist creating"
     mkdir -p $KEYS_DIR
fi


cd $KEYS_DIR

if [ $do_step_install = true ]
  then
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
      STEP_LATEST_DOWNLOAD=https://dl.step.sm/gh-release/cli/gh-release-header/v0.24.4/step_linux_0.24.4_amd64.tar.gz 
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
    echo "Removing unneeded temp location"
    rm -rf step_*
  else 
    echo "Skipping step download"
fi

echo Root certificate processing
if [ -x $KEYS_DIR/step ]
  then
    if [ -f $KEYS_DIR/root.crt ] 
      then
        echo "Root certificate already exists, not creating"
      else
        echo "Creating root certificate"
        $KEYS_DIR/step certificate create root.cluster.local $KEYS_DIR/root.crt $KEYS_DIR/root.key --profile root-ca --no-password --insecure --kty=RSA
    fi
  else
    if [ -f $KEYS_DIR/root.crt ] 
      then
        echo "Step command does not exist, other scripts may fail, Root certificate already exists you may be able to reuse it"
      else
        echo "WARNING WARNING WARNING WARNING the step command does not exist and there are no pre-existing root.crt so you will need to install step and create the certificates by hand"
        exit -1
    fi
fi 