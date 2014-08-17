#!/usr/bin/env perl

use warnings;
use strict;
use Carp;
use Data::Dumper;
use Getopt::Long;

$SIG{__DIE__} = \&Carp::confess;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Audio::Score;

my %opt;

GetOptions (
    "print" => \$opt{print},
    "help" => sub { print "usage: $0 [--print] <scorefile> <scorefile> ...\n"; exit 0; },
) or die "Bad options, see $0 --help";

my $play = Audio::Score->new;

while (<>) {
    $play->parse_line($_);
};



# print Dumper ( [$play->engine->get_sounds] );

# print join " ", $play->engine->make_arg; 

if ($opt{print}) {
    $play->engine->pipe_sound( \*STDOUT )
} else {
    $play->engine->run;
};
