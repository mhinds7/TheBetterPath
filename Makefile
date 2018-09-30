

PROGS	:= walk.pl mkmap.pl
NAMES	:= $(sort $(notdir $(basename $(wildcard */*.map))))
MAPS	:= $(addprefix data/, $(addsuffix .map, $(NAMES)))
OUTS	:= $(addprefix data/, $(addsuffix .out, $(NAMES)))
CHKS	:= $(addprefix data/, $(addsuffix .chk, $(NAMES)))

check:	$(addsuffix .chk, $(basename $(PROGS))) $(OUTS) $(CHKS)
clean:;	rm -f data/*.out

.PHONY:		check clean .chk
.SUFFIXES:
.SUFFIXES:	.map .out .chk .pl

%.chk:		%.pl
		@perl -cW $*.pl

%.out:		%.map
		@./walk.pl $*.map > $*.out

%.chk:		%.out
		@./check.sh $*.ref $*.out

