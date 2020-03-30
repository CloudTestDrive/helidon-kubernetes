#/bin/bash -f
echo Service IP address is $1
curl -i -k -X PUT -u jack:password https://$1/sm/stocklevel/Pins/5000
curl -i -k -X PUT -u jack:password https://$1/sm/stocklevel/Pencil/200
curl -i -k -X PUT -u jack:password https://$1/sm/stocklevel/Eraser/50
curl -i -k -X PUT -u jack:password https://$1/sm/stocklevel/Book/100