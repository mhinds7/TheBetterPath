

PROGS	:= walk.pl mkmap.pl
NAMES	:= $(sort $(notdir $(basename $(wildcard */*.map))))
MAPS	:= $(addprefix data/, $(addsuffix .map, $(NAMES)))
OUTS	:= $(addprefix data/, $(addsuffix .out, $(NAMES)))
CHKS	:= $(addprefix data/, $(addsuffix .chk, $(NAMES)))
RES	:= $(addprefix data/, $(addsuffix .res, $(NAMES)))

all:	clean progs outs checks
progs:	$(addsuffix .chk, $(basename $(PROGS)))
outs:	$(OUTS)
checks:	outs $(CHKS)
updref:	outs
	./update-refs.sh
res:	$(RES)
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

%.res:		%.out
		@printf "%-16s `tail -n1 $*.out`\n" $*.out

