#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use My::Score::Instrument;
use My::Score::Note;
use My::Score::Tune;

open (my $fd, ">", \(my $content));

my $instr = My::Score::Instrument->new(harmonics => { 1=>3, 2=>2, 3=>1});
my $note = My::Score::Note->new( 
    start => 50, len => 10, tone=>"A", vol => 13);
my $tune = My::Score::Tune->new( notes => [$note], meter => 1, tempo=>60 );

$instr->play_to_fd( $fd, $tune );

my @lines = split /\n/, $content;

is ( scalar @lines, 3, "3 sounds produced" );
foreach (@lines) {
    ok ( $_ =~ qr/^50 10 (\d+) (\d+(\.\d+)?)$/, "note like note")
        or next;
    ok ( $1, "pitch present" );
    is ( $1%440, 0, "Frequency = 440*n" );
};

note $content;

done_testing;
