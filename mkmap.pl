#! /usr/bin/perl

my ($Nrows, $Ncols, $SR, $SC, $ER, $EC) = @ARGV;
defined($EC) || die("Usage mkMap <Nrows> <Ncols> <SR> <SC> <ER> <EC>");
$SR >= 0 && $SR < $Nrows || die("SR $SR $Nrows");
$ER >= 0 && $ER < $Nrows || die("ER $ER $Nrows");
$SC >= 0 && $SC < $Ncols || die("SC $SC $Ncols");
$EC >= 0 && $EC < $Ncols || die("EC $EC $Ncols");

for (my $r=0; $r<$Nrows; $r++) {
    for (my $c=0; $c<$Ncols; $c++) {
        print(rand(1) > 0.67 ? '_' : 'X');
    }
    print("\n");
}
print("$SR $SC $ER $EC\n");
