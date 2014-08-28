#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use YAML;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use My::Score::Parser;

my %opt;
GetOptions (
    "dump" => \$opt{dump},
    "print" => \$opt{print},
    "record=s" => \$opt{record},
    "help" => sub { print "usage: $0 [--print] <scorefile> <scorefile> ...\n"; exit 0; },
) or die "Bad options, see $0 --help";

my $play = My::Score::Parser->new;

while (<>) {
    $play->parse_line($_);
};

if ($opt{dump}) {
    warn Dump($play); #->dump;
};

if ($opt{print}) {
    $play->play_to_fd( \*STDOUT );
} else {
    my $pl = "$Bin/csynth";
    my $format = "-t raw -e signed -b 32 -r 44100 -c 1 -";
    my $cmd = defined $opt{record} 
        ? "sox $format $opt{record}" : "play $format";
    open (my $fd, "|-", "$pl | $cmd" )
        or die "Cannot start $cmd: $!";
    $play->play_to_fd($fd);
};

