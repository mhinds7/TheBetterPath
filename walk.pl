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
#y @Around = ([1,  1], [ 1, 0], [1,-1], [0,-1], [0, 1], [-1,1], [-1,0], [-1,-1]);
my @Around = ([-1,-1], [-1, 0], [0,-1], [0, 1], [1,-1], [1, 0], [-1,1], [ 1, 1]);


my $StepAroundStr;
# make stepAround
{
#   my @ordered = qw(0 1 2 3 4 5 6 7);
    my @ordered = @Around;
    my @scrambled = @Around;
#   my @scrambled;
#   while (@ordered) { push(@scrambled, splice(@ordered, rand(@ordered), 1)) }

    my @code;
    my @dump;
    for my $ar (@scrambled) {
        my ($dr, $dc) = @$ar;
        push(@dump, sprintf("%2d%2d", $dr, $dc));
        if ($dr > 0) { $dr='+'.$dr } elsif ($dr == 0) { $dr='  ' }
        if ($dc > 0) { $dc='+'.$dc } elsif ($dc == 0) { $dc='  ' }
        push(@code, "step(\$r$dr,\$c$dc)");
    }
    $StepAroundStr = join('  ', @dump);
    my $code = "sub stepAround { my(\$r,\$c)=\@_;return\n".join(" ||\n", @code)." } 1\n";
    eval($code) || die("Bad code\n$@");
}

my (@Map, @Path, @Steps);
my ($SR, $SC, $ER, $EC);
my ($Nrows, $Ncols) = (0, undef);

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
    my @depths;
    if (step($SR, $SC)) {
        my $depth = scalar(@Steps);
        push(@depth, $depth);
        dumpPath($depth);
        if ((my $depth2 = minPath()) != $depth) {
            printf("Minimized %d steps\n", $depth - $depth2);
            push(@depth, $depth2);
            dumpPath($depth2);
        }
        else { push(@depth, 0) }
        printf("Depth %3d %3d Around %s\n", @depth, $StepAroundStr);
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
    if ($Map[$r][$c] ne 'X') { return }
    $Map[$r][$c] = 'Y';
    $Path[$r][$c] = push(@Steps, [ $r, $c ]);
    if ($r == $ER && $c == $EC) { return 1 }

    stepAround($r, $c) && return 1;

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

