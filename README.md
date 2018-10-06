# TheBetterPath
Find a better path through a simple tile map

## Use
Simply type make

## Files
```
README.txt      This file
walk.pl         Parse and tranverse a simple map
mkmap.pl        Create a random map for use by walk.pl
check.sh        Reference comparision helper script
Makefile        Run the walker on all the maps
data/*map       Input map files
data/*ref       Reference Comparison files for regression test
```
## Todo

Another trick we should try to compute a more optimal search
strategy for the static Surrounding Offset Vector (SOV).
Make the SOV point from the Start coord to the End coord

Possibley better still dynamically change the SOV to point
from the Current coord to the End coord.

Done - 2018-10-06
We should do the path minimization as part of the return
from each step. Upon success the steps should return surrounding
tile of minimum depth to the caller which in turn does the
same. This should be somewhat more efficient than minimizing
by post processing the path.

