#!/bin/bash -f
i=0
while true;do
i=$[$i+1]
echo test $i
curl -s -k -X GET -u jack:password https://store.$1.nip.io/store/stocklevel > /dev/null
# Do a little sleep so we don't totally overload the server
sleep $2
done