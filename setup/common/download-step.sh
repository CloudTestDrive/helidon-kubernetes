#!/bin/bash -f


step_dir=$HOME/keys

remove=false
if [ $# -gt 0 ]
  then
    if [ $1 = replace ]
      then
        remove=true
    fi
fi

do_step_install=true
if [ -d $step_dir ]
  then 
    echo Step instalation directory $step_dir already exists
    if [ $remove = true ]
      then
        echo Removing $step_dir and all of its contents
        rm -rf $step_dir
        mkdir -p $step_dir
      else
        echo Wont remove $step_dir unless you add a 2nd argument to this script with a value of replace
        echo Will skip download of step and attempt to continue using existing step setup
        do_step_install=false
    fi   
  else
     echo $step_dir does not exist creating
     mkdir -p $step_dir
fi


cd $step_dir

if [ $do_step_install = true ]
  then
    echo Locating download page for latest version of step and removing whitespace
    LATEST_STEP_URL=`curl -i -s https://github.com/smallstep/cli/releases/latest | grep -i location: | awk '{print $2}'  | sed -e 's/[\r]//g' | tr -d '\n'`
    echo Latest version location page is $LATEST_STEP_URL
    echo Identifying latest Version of step download linkk
    STEP_LATEST_DOWNLOAD=`curl -i -s -X GET $LATEST_STEP_URL | grep dl.step.sm | grep step_linux | grep amd64.tar.gz | xmllint  --xpath 'string(/li/a/@href)' -`
    echo Latest step download location is $STEP_LATEST_DOWNLOAD
    echo Downloading step
    wget -O step.tar.gz $STEP_LATEST_DOWNLOAD
    echo Extrating step to temp location
    tar -xf step.tar.gz
    echo Removing download file
    rm step.tar.gz
    echo moving step into place
    mv step_*/bin/step .
    echo removing unneeded temp location
    rm -rf step_*
  else 
    echo Skipping step download
fi

echo Root certificate processing
if [ -x $step_dir/step ]
  then
    if [ -f root.crt ] 
      then
        echo Root certificate already exists, not creating
      else
        echo Creating root certificate
        ./step certificate create root.cluster.local root.crt root.key --profile root-ca --no-password --insecure
    fi
  else
    if [ -f root.crt ] 
      then
        echo Step command does not exist, other scripts may fail, Root certificate already exists you may be able to reuse it
      else
        echo WARNING WARNING WARNING WARNING the step command does not exist and there are no pre-existing root.crt so you will need to install step and create the certificates by hand
        exit -1
    fi
fi 