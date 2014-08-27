#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use Scalar::Util qw(looks_like_number);

use My::Score::Parser;
use My::Score::Instrument;

my $bare = My::Score::Instrument->new( harmonics => { 1=>1 } );

test_snippet(
    ["chord A"],
    ["0 0.25 440 0+-999"],
);

test_snippet(
    ["set base 1200", "chord A,M3,P5"],
    ["0 0.25 440 0+-999","0 0.25 550+-10 0+-999","0 0.25 660+-10 0+-999", ],
);

test_snippet([
        "set base 12 meter 1 tempo 60",
        "--",
        "chord 0,12",
    ],[
        "1 1 440 0+-999",
        "1 1 880 0+-999",
    ]);


done_testing;

my $snip;
sub test_snippet {
    my ($input, $likes) = @_;

    $snip++;
    my $play = My::Score::Parser->new( instrument => $bare );
    my $n;
    my @err;
    foreach (@$input) {
        chomp;
        $n++;
        eval {
            $play->parse_line($_);
            1
        } or push @err, "Line $n: $_: $@";
    };
    if (@err) {
        my $err = scalar @err;
        diag "Snippet $snip had exceptions:\n".join "",@err;
        return fail "Snippet $snip had $err errors";
    };

    open my $fd, ">", \(my $content)
        or die "Write to memory failed";
    $play->play_to_fd($fd);
    close $fd;

    my @out = split /\n/, $content;

    eval {
        for (my $i = 1; $i < @out; $i++) {
            $out[$i-1] =~ /^(\d+(\.\d+)?)/ 
                or die "No start time in output line ".($i-1);
            my $t1 = $1;
            $out[$i] =~ /^(\d+(\.\d+)?)/ 
                or die "No start time in output line $i";
            my $t2 = $1;
            $t1 <= $t2 or die "Start times out of order";
        };
    };
    if ($@) {
        diag "Bad output from synth: \n$content";
        return fail "Bad output from synth";
    };

    my @badspec;
    SPEC: foreach my $spec (@$likes) {
        foreach my $line (@out) {
            test_line ($line, $spec) or next;
            $line = ''; 
            next SPEC;
        };
        push @badspec, $spec; 
    };
    my @badlines = grep { length } @out;

    return pass( "Snippet $snip had ".(scalar @out)
        ." sounds of expected form" )
        unless @badlines + @badspec;

    diag "Unexpected lines:\n".join "\n", @badlines;
    diag "Lines not found:\n".join "\n", @badspec;

    return fail( "Spinnet $snip had unexpected sounds" );
};

sub test_line {
    my ($input, $criteria) = @_;

    my @input = split /\s+/, $input;
    my @todo = split /\s+/, $criteria;
    return '' unless @input == @todo;

    for (my $i = 0; $i<@todo; $i++) {
        if ($todo[$i] =~ /^(-?\d+(?:\.\d*)?)\+-(\d+(?:\.\d*)?)$/) {
            my ($x, $eps) = ($1, $2);
            looks_like_number($input[$i]) or return '';
            abs ($input[$i] - $x) < $eps or return '';
        } else {
            $todo[$i] eq $input[$i] or return '';
        };
    };

    return 1;
};

