#!/usr/bin/env perl

use warnings;
use strict;
use Carp;
use Data::Dumper;

$SIG{__DIE__} = \&Carp::confess;

use Audio::Score;

my $play = Audio::Score->new;

while (<>) {
    $play->parse_line($_);
};

print Dumper ( [$play->engine->get_sounds] );

print join " ", $play->engine->make_arg; 

$play->engine->run;

