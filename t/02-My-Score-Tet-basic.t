#!/usr/bin/env perl

use warnings;
use strict;
use Test::More;

use My::Score::Tet;

my $t12 = My::Score::Tet->tet(12);

is ($t12->interval(1), 0, "log 1 == 0");

note "intervals";
ok_note($t12, "P1", 0);
ok_note($t12, "m2", 1);
ok_note($t12, "M2", 2);
ok_note($t12, "m3", 3);
ok_note($t12, "M3", 4);
ok_note($t12, "P4", 5);
ok_note($t12, "d5", 6);
ok_note($t12, "P5", 7);
ok_note($t12, "m6", 8);
ok_note($t12, "M6", 9);
ok_note($t12, "m7", 10);
ok_note($t12, "M7", 11);
ok_note($t12, "P8", 12);

note "Just scale";
# ut skipped
ok_note($t12, "9/8", 2);
ok_note($t12, "5/4", 4);
ok_note($t12, "4/3", 5);
ok_note($t12, "6/4", 7);
ok_note($t12, "5/3", 9);
ok_note($t12, "15/8", 11);
ok_note($t12, "16/8", 12);

foreach (0..12) {
    cmp_ok ($t12->pitch($_), "==", 2**($_/12), "Pitch 2^$_/12");
};

note "Some 19-TET";

my $t19 = My::Score::Tet->tet(19);
ok_note($t19, "1", 0);
ok_note($t19, "9/8", 3);
ok_note($t19, "5/4", 6);
ok_note($t19, "4/3", 8);
ok_note($t19, "6/4", 11);
ok_note($t19, "5/3", 14);
ok_note($t19, "15/8", 17);
ok_note($t19, "16/8", 19);

foreach (1, 4, 7, 19) {
    cmp_ok ($t19->pitch($_), "==", 2**($_/19), "Pitch 2^$_/19");
};

note "12-TET 5th dissonance ", $t12->dissonance(3/2);
cmp_ok ($t12->dissonance(3/2), "<=", -1.9, "12-TET 5th dissonance (<)");
cmp_ok ($t12->dissonance(3/2), ">=", -2, "12-TET 5th dissonance (>)");

note "19-TET 5th dissonance ", $t19->dissonance(3/2);
cmp_ok ($t19->dissonance(3/2), "<=", -7, "19-TET 5th dissonance (<)");
cmp_ok ($t19->dissonance(3/2), ">=", -7.5, "19-TET 5th dissonance (>)");

note "29-TET 5th dissonance ", My::Score::Tet->tet(29)->dissonance(3/2);
note "31-TET 5th dissonance ", My::Score::Tet->tet(31)->dissonance(3/2);
note "53-TET 5th dissonance ", My::Score::Tet->tet(53)->dissonance(3/2);

foreach (qw(9/8 6/5 5/4 4/3 3/2 5/3 7/4 15/8)) {
    note "12-TET dissonance($_) = ".$t12->dissonance($_);
    note "19-TET dissonance($_) = ".$t19->dissonance($_);
};
foreach (12, 19, 31, 53) {
note "$_-TET weighted dissonance over natural scale: ", 
    My::Score::Tet->tet($_)->weighted_dissonance(
        9/8=>1, 5/4=>1, 4/3=>1, 3/2=>1, 5/3=>1, 15/8=>1);
};

done_testing;

sub ok_note {
    my ($tet, $interval, $steps) = @_;

    is( $tet->interval($interval), $steps, 
        "interval $interval is $steps steps in ".$tet->base."-TET" );
};
