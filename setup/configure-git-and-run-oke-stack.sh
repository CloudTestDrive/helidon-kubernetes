if [ $# -lt 2 ]
  then
    echo "Missing arguments, you must provide the name of the namespace to use and the External IP address of the ingress controller service in that order"
    exit -1
fi
if [ $# -eq 2 ]
   then
     echo About to configure using a department name of $1, an namespace of $1 and a ingress eternal IP of $2
     read -p "Proceed ?  " -n 1 -r
     echo    # (optional) move to a new line
     if [[ ! $REPLY =~ ^[Yy]$ ]]
     then
        echo OK, exiting
        exit 1
     fi
fi
cd kubernetes-labs
echo Configuring git repo with department of $1
bash ./configure-downloaded-git-repo.sh $1 skip
echo Configuring Kubernetes namepace $1 using ingress external IP of $2
bash ./executeRunStack.sh $1 $2