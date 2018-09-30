#! /bin/bash

echo -n "$2 check "
if [[ "$(diff -q $1 $2)" != "" ]]; then
  echo Fail
  exit 1
fi

echo OK
exit 0

