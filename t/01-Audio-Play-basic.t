#!/usr/bin/env perl

use warnings;
use strict;
use Test::More;

use Audio::Play;

my $play = Audio::Play->new;
$play->add_sound( pitch => 440, vol => 10, start => 0, len => 10 );
$play->add_sound( pitch => 550, vol => 10, start => 1.5, len => 7 );
$play->add_sound( pitch => 660, vol => 10, start => 3, len => 4 );

note join " ",$play->make_arg;

is ($play->max_volume, 30, "Max volume check");

done_testing;
