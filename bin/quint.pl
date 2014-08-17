#!/usr/bin/perl -w

use strict;

my ($base, $tertia, $quint) = @ARGV;

my $note = 0;
my @plus = ( 0, $tertia, $quint, $tertia );

print "set base $base key 440 meter 4 speed 30 vol -6\n";
printf "0: chord %d,%d,%d len 4 oct -3\n", @plus[0,1,2];
printf "0: chord %d,%d,%d len 4 oct -2\n", @plus[0,1,2];
printf "0: chord %d,%d,%d len 4 oct -1\n", @plus[0,1,2];
print "--";
foreach my $unused (0..$base) {
    printf "0: chord %d,%d,%d len 5 vol -12\n", @plus[0,1,2];
    printf "$_: chord $plus[$_]\n" for 0..$#plus;
    print "--\n";
    $_ -= $quint for @plus;
    if ($plus[0] < 0) {
        $_ += $base for @plus;
    };
};
printf "0: chord %d,%d,%d len 4 vol -6 oct -1\n", @plus[0,1,2];



