#! /bin/bash

echo -n "$2 check "
if [[ "$(diff -q $1 $2)" != "" ]]; then
  echo Fail
else
  echo OK
fi

exit 0

