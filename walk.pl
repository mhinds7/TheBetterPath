#! /usr/bin/perl

# Recursively walk the map provided by the input file
# If a path is found then dump and minimize the path.
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
# The result of such walks is very non-optimal, so I added
# a fairly simple path minimizer. While it does minimize
# the path found by the recursive walker, it does not find
# the shortest possible path. This is illustrated by input
# files t7, t7a and t8, t8a

# Offsets of the surrounding tiles from a given central tile
my @Around = ([1, 1], [1, 0], [1,-1], [0,-1], [0,1], [-1,1], [-1,0], [-1,-1]);

my (@Map, @Path, @Steps);
my ($SR, $SC, $ER, $EC);
my ($Nrows, $Ncols) = (0, undef);
my $Nsteps = 0; # Total number of steps

sub step($$);
sub minPath();
sub dumpPath($);

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
        my $depth = scalar(@Steps);
        dumpPath($depth);
        my $depth2 = minPath();
        if ($depth2 != $depth) {
            printf("Minimized %d steps\n", $depth - $depth2);
            dumpPath($depth2);
        }
        printf("Walk %4d %3d %3d %3d", $Nsteps, $depth, $depth2, $depth2 - $depth);
        exit(0);
    }
    else {
        print("No Path Found\n");
        exit(1);
    }
}

sub step($$)
{
    my ($r, $c) = @_;
#   These are the boundary test elimated by the guards
#   if ($r >= $Nrows || $c >= $Ncols || $r < 0 || $c < 0) { return }
    $Nsteps++;
    if ($Map[$r][$c] ne 'X') { return }
    $Map[$r][$c] = 'Y';
    $Path[$r][$c] = push(@Steps, [ $r, $c ]);
    if ($r == $ER && $c == $EC) { return 1 }

    if (step($r+1, $c+1) ||
        step($r+1, $c  ) ||
        step($r+1, $c-1) ||
        step($r  , $c-1) ||
        step($r  , $c+1) ||
        step($r-1, $c+1) ||
        step($r-1, $c  ) ||
        step($r-1, $c-1)) { return 1 }

     $Path[$r][$c] = 0;
     pop(@Steps);
     return undef;
}

# Minimize a path by finding shortcuts
# and eliminating the unecessary intervening steps.
sub minPath()
{
    my @dels; # remember the deleted steps here

    # Go thru each step and find if it contacts
    # a step ealier than its immediate predecssor
    # by finding the min path depth of the surrounding tiles.
    for (my $d=0; $d<@Steps; $d++) {
        my ($r, $c) = @{$Steps[$d]};
        my $min = $d;
        for my $ar (@Around) {
            my $dep = \$Path[$r+$ar->[0]][$c+$ar->[1]]; # Save expensive/ugly ref
            if ($$dep && $$dep <= $min) { $min = $$dep }
        }
        # Found shortcut, delete intervening steps
        if ($min < $d) {
            for (my $dx=$min; $dx < $d; $dx++) {
                my ($x, $y) = @{$Steps[$dx]};
                $Path[$x][$y] = undef;
                $dels[$dx] = 1;
            }
        }
    }

    # Renumber the steps in the Path
    my $dx = 0;
    for (my $d=0; $d<@Steps; $d++) {
        if (!$dels[$d]) {
            my ($r, $c) = @{$Steps[$d]};
            $Path[$r][$c] = ++$dx;
        }
    }
    return $dx;
}

sub dumpPath($)
{
    my $l = length($_[0])+1;
    print("      ");
    for (my $c=0; $c<$Ncols; $c++) { printf("%-*d", $l, $c) }
    print("\n".(my $xx = "    +".('-'x($l*$Ncols))."-+\n"));
    for (my $r=1; $r<=$Nrows; $r++) {
        printf("%3d | ", $r-1);
        for (my $c=1; $c<=$Ncols; $c++) {
            if (my $depth = $Path[$r][$c]) { printf('%-*d', $l, $depth) }
            else                             { printf('%*s', $l, '') }
        }
        print("|\n");
    }
    print($xx);
}

