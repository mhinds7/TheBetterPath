#! /usr/bin/perl

# Recursively walk the map provided by the input file
# If a path is found then dump raw and minimized the paths.
#
# To significantly reduce the number boundary tests
# a gaurd band of '*' is placed around the input data
# such that X_XX becomes ******
#           XX_X         *XX_X*
#           XXX_         *XXX_*
#           XXX_         *XXX_*
#                        ******
# This optimization does make indexing a bit confusing...
#
# The raw result of the recursive walk is very non-optimal,
# so while walking backwards over the found path step to least
# deep adjacent path step - take a shortcut. This greatly
# minimizes the path, but does not find the shortest possible path.
# This is illustrated by input files t7..9 and t7a..9a

# Offsets of the surrounding tiles from a given central tile
my @Around1 = ([ 1, 1], [ 1, 0], [ 1,-1], [ 0,-1], [ 0, 1], [-1, 1], [-1, 0], [-1,-1]);
my @Around2 = ([-1,-1], [-1, 0], [-1, 1], [ 0,-1], [ 0, 1], [ 1,-1], [ 1, 0], [ 1, 1]);

my (@Map, @Depths, @Steps, @MinSteps);
my ($SR, $SC, $ER, $EC);
my ($Nrows, $Ncols) = (0, undef);
my $Nsteps = 0; # Total number of steps

sub step($$);
sub dumpSteps($);

# Pretend there is a main sub context
#main
{
    # Read in the file, adding column guards as we go
    while (<>) {
        print;
        scalar(($SR, $SC, $ER, $EC) = /(\d+)/g) != 4 || last;
        my @row = ('*', /[_X]/g, '*');
        if (!defined($Ncols)) { $Ncols = scalar(@row)-2 }
        elsif ($Ncols != scalar(@row)-2) { die("Ncols mismatch") }
        $Map[$Nrows++] = [ @row ];
    }
    print("\n");
    defined($SR) || die("Missing Start/End");

    # Validate and correct the Start and End for Guard indexing
    $SR >= 0 && $SR < $Nrows ? $SR++ : die("SR $SR $Nrows");
    $ER >= 0 && $ER < $Nrows ? $ER++ : die("ER $ER $Nrows");
    $SC >= 0 && $SC < $Ncols ? $SC++ : die("SC $SC $Ncols");
    $EC >= 0 && $EC < $Ncols ? $EC++ : die("EC $EC $Ncols");

    # Add top and bottom guard rows
    unshift(@Map, [ split('', '*'x($Ncols+2)) ]);
    push(@Map, [ split('', '*'x($Ncols+2)) ]);

    # Recursively walk the Map
    if (step($SR, $SC)) {
        my $depth = dumpSteps(\@Steps);
        my $depth2 = scalar(@MinSteps);
        if ($depth != $depth2) {
            printf("Minimized 425 %d steps\n", $depth - $depth2);
            dumpSteps(\@MinSteps);
        }
        printf("Walk %4d %3d %3d %3d\n", $Nsteps, $depth, $depth2, $depth2 - $depth);
        exit(0);
    }
    else {
        printf("No Path Found %d\n", $Nsteps);
        exit(0);
    }
}

my $dmpCnt = 0;
sub dumpMap
{
#D  ++$dmpCnt % 20 == 0 || return;
    my $buf = "\x1b\x5b\x48\x1b\x5b\x32\x4a";
    print(STDERR $buf.join('', map { join('', @$_)."\n" } @Map));
    select(undef, undef,undef, 0.002);
}

sub step($$)
{
    my ($r, $c) = @_;
#   These are the boundary test elimated by the guards
#   if ($r >= $Nrows || $c >= $Ncols || $r < 0 || $c < 0) { return }
    $Nsteps++;
    if ($Map[$r][$c] ne 'X') { return }
#D  dumpMap();
    $Map[$r][$c] = ' ';
    $Depths[$r][$c] = push(@Steps, [ $r, $c ]);
    if ($r == $ER && $c == $EC) {
        $Map[$r][$c] = 'Z';
        unshift(@MinSteps, [ $r, $c ]);
        goto unwind
    }
    elsif (my $rc = 
        step($r+1, $c+1) ||
        step($r+1, $c  ) ||
        step($r+1, $c-1) ||
        step($r  , $c-1) ||
        step($r  , $c+1) ||
        step($r-1, $c+1) ||
        step($r-1, $c  ) ||
        step($r-1, $c-1)) {
            ref($rc) || return $rc;
            ($r, $c) = @$rc;
            goto unwind
    }
    else {
        $Map[$r][$c] = '.';
#D      dumpMap();
        pop(@Steps);
        return $Depths[$r][$c] = undef;
    }

unwind:
    # Walk the path backwards finding shortcuts
    # as we go by find the step of min dep and
    # returning that to the caller.
    my ($min, $minrc) = ($Depths[$r][$c], [$r,$c]);
    my ($m1, $r1, $c1, $rc) = ($min, $r, $c);
    for my $ar (@Around2) {
        ($r1, $c1) = ($r+$ar->[0], $c+$ar->[1]);
        my $mp = \$Map[$r1][$c1];
        if ($$mp eq ' ') {
            $$mp = 'Z';
            my $dp = \$Depths[$r1][$c1];
            if ($$dp && $$dp <= $m1) {
                $m1 = $$dp;
                $minrc = [$r1,$c1];
            }
        }
    }
    unshift(@MinSteps, $minrc);
    return $minrc->[0] == $SR && $minrc->[1] == $SC ? 1 : $minrc;
}

sub dumpSteps($)
{
    my $steps = $_[0];
    my $depth = scalar(@$steps);
    my $l = length($depth)+1;
    print("      ");
    my @path;
    my $d = 0;
    for my $rc (@$steps) { $path[$rc->[0]][$rc->[1]] = ++$d }
    for (my $c=0; $c<$Ncols; $c++) { printf("%-*d", $l, $c) }
    print("\n".(my $xx = "    +".('-'x($l*$Ncols))."-+\n"));
    for (my $r=1; $r<=$Nrows; $r++) {
        printf("%3d | ", $r-1);
        for (my $c=1; $c<=$Ncols; $c++) {
            if ($d = $path[$r][$c]) { printf('%-*d', $l, $d) }
            else                    { printf('%*s', $l, '') }
        }
        print("|\n");
    }
    print($xx);
    return $depth;
}

