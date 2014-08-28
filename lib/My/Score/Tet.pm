package My::Score::Tet;
use Moo;

use Scalar::Util qw(looks_like_number);

has base => is => "ro", required => 1;

has pitch_cache => is => "ro", default => sub { {}; };
has ratio_cache => is => "ro", default => sub { {}; };

our %tets;
sub tet {
    my ($class, $base) = @_;
    return $tets{$class}{$base} ||= $class->new( base => $base );
};

sub pitch {
    my ($self, $n) = @_;

    return $self->pitch_cache->{$n} //= 2**($n/$self->base);
};

sub translate_note {
    my ($self, $note) = @_;

    my $step = $note->tone =~ /^(-?\d+)$/ ? $1 : $self->interval( $note->tone );
    $note->rel and $step += $self->translate_note($note->rel);
    $note->oct and $step += $note->oct*$self->base;

    return $step;
};

my %interval2ratio = (
    P1 => "1/1",
    A1 => "25/24",
    m2 => "16/15",
    M2 => "9/8",
    m3 => "6/5",
    M3 => "5/4",
    P4 => "4/3",
    P5 => "3/2",
    m6 => "8/5",
    M6 => "5/3",
    P7 => "7/4",
    m7 => "16/9",
    M7 => "15/8",
    P8 => "2/1",
);

my %note2ratio = (
    C => "1/1",
    D => "8/9",
    E => "5/4",
    F => "4/3",
    G => "3/2",
    A => "5/3",
    B => "15/8",
);

my %alter = (
    ''  => 0,
    b   => -1,
    '#' => +1,
);

sub interval {
    my ($self, $int) = @_;

    return $self->ratio_cache->{$int} //= $self->_interval($int)
        // die "Cannot parse interval '$int'";
};

sub _interval {
    my ($self, $int) = @_;

    $int =~ /^(\d+)\/(\d+)$/ and $int = $1/$2;
    looks_like_number($int) 
        and return int ( ($self->base * (log $int) / log 2) + 0.5 );

    if ($int =~ /^(.*)([b#])$/) {
        return $self->_interval( $1 ) + $alter{$2} * $self->interval("A1");
    };

    my $ratio = $interval2ratio{$int};
    return $self->_interval( $ratio )
        if $ratio;

    if ($int =~ /^([A-G])$/) {
        return - $self->interval( $note2ratio{A} )  
            + $self->interval( $note2ratio{$1} );
    };

    $int =~ /^-(.*)$/ and return -$self->_interval($1);

    # Now let's detect...
    $int =~ /^([dmPMA])([1-9]\d*)$/
        or die "Wrong interval format: $int";
    my ($type, $n) = ($1, $2);

    # handle flattened & sharpened intrevals
    $type eq 'd' 
        and return ($self->_interval("m$n") || $self->_interval("P$n"))
                -$self->interval("A1");
    $type eq 'A' 
        and return ($self->_interval("M$n") || $self->_interval("P$n"))
                +$self->interval("A1");

    # autodetect octave+
    if ($n > 8) {
        my $try = $self->_interval($type.($n-7)) + $self->base;
    };

    return $self->_interval( $ratio )
        if $ratio;
    return;
};

sub isnt_good {
    my $self = shift;

    my @bad_combo;
    # Check that interval1 + intreval2 == interval3 holds for all pure intervals
    # TODO rewrite this rubbish
    foreach my $i1 (values %interval2ratio) {
        foreach my $i2 (values %interval2ratio) {
            foreach my $i3 (values %interval2ratio) {
                my $combine = eval "$i1*$i2/($i3)";

                my ($power) = grep { $combine == 2**$_ } -2..2;
                $power or next;


                $self->interval($i1) + $self->interval($i2) 
                    == $self->interval($i3) + $power * $self->base
                or push @bad_combo, "$i1+$i2 != $i3";
            };
        };
    };

    return @bad_combo;
};

# usage:
# dissonance( nnnn )
# dissonance( nnn => 1, mmm => 2, ... ) - weighted sum
sub weighted_dissonance {
    my $self = shift;
    my %profile = @_;

    my $err = 0;
    my $norm = 0;
    while (my ($int, $wt) = each %profile) {
        $err += $wt * abs($self->dissonance($int));
        $norm += $wt;
    };
    return $err/$norm; # 1200 => cents (100ths of semitone)
};

sub dissonance {
    my ($self, $ratio) = @_;

    $ratio =~ /(\d+)\/(\d+)/
        and $ratio = $1/$2;
    my $pitch = $self->pitch( $self->interval($ratio) );
    return 1200 * log ($pitch / $ratio) / log 2;
};

my @tuning_checks = (
    [ "10/9", "m2", "A1" ],
    [ "m3", "m2", "M2" ],
    [ "M3", "M2", "10/9" ],
    [ "P5", "M3", "m3" ],
    [    2, "P5", "10/9", "m3" ],
);

sub check_intervals {
    my $self = shift;

    my @bad;
    foreach my $sample( @tuning_checks ) {
        my ($sum, @parts) = map { $self->interval($_) } @$sample;
        $sum -= $_ for @parts;
        $sum != 0 and push @bad,
            "$sample->[0] != ".join " + ", @$sample[1..$#$sample];
    };

    return @bad;
};

our @main_intervals = qw(16/15 10/9 9/8 6/5 5/4 4/3 3/2 5/3 7/4 11/8 13/8);
sub examine {
    my $self = shift;

    my %intervals = map { $_ => $self->interval($_) } @main_intervals;
    my @bad = $self->check_intervals;
    my %dissonance => map { $_ => $self->dissonance($_) } @main_intervals;
    my $total_dissonance = $self->weighted_dissonance( map { $_=>1 } @main_intervals);
    
    return {
        steps => $self->base,
        intervals => \%intervals,
        has_second => ($self->interval(10/9) == $self->interval(9/8) ? 1 : 0),
        bad_intervals => (@bad ? \@bad : undef),
        dissonance => \%dissonance,
        total_dissonance => $total_dissonance,
    };
};

1;
