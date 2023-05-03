#!/bin/bash -f

COLSTART="{\"items\":["
COLBUILD=""
COLEND="]}"

for ((i=1; i<=$#; i++))
do

  if [ $i -ge 2 ]
  then
    COLBUILD="$COLBUILD","${!i}"
  else
    COLBUILD="${!i}"
  fi
done

echo "$COLSTART""$COLBUILD""$COLEND"