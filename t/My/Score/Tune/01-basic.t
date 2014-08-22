#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use My::Score::Tune;

my $tune = My::Score::Tune->new;

foreach my $interval ( qw( 1/1 9/8 5/4 4/3 3/2 5/3 15/8 2/1 )) {
    $tune->add_chord( notes => [ $interval ] );
    $tune->advance_tack;
};

my @sound = $tune->play;

is (scalar @sound, 8, "8 notes");
is ($sound[0]->pitch, 440, "la start");
is ($sound[-1]->pitch, 880, "la end");
is ($sound[-1]->to_string, "7 0.25 880 1", "sound tostring check");

note explain @sound;

done_testing;
