#! /bin/sh

sh -xc "$(ls data/*.out | sed -e 's/\(.*\).out/mv \1.out \1.ref;/')"

