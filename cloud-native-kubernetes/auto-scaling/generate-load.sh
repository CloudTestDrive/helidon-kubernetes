#!/bin/bash -f
i=0
while true;do
i=$[$i+1]
echo Iteration $i
curl -k -X GET -u jack:password https://$1/store/stocklevel
# Do a little sleep so we don't totally overload the server
sleep $2
done
