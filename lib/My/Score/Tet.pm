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

my %interval2ratio = (
    P1 => 1,
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
    P8 => 2,

);

my %notes = (
    do  => 1,
    re  => 9/8,
    mi  => 5/4,
    fa  => 4/3,
    sol => 3/2,
    la  => 5/3,
    si  => 15/8,
);

sub interval {
    my ($self, $int) = @_;

    return $self->ratio_cache->{$int} //= $self->_interval($int)
        // die "Cannot parse interval '$int'";
};

sub _interval {
    my ($self, $int) = @_;

    $int =~ /(\d+)\/(\d+)/ and $int = $1/$2;
    looks_like_number($int) 
        and return int ( ($self->base * (log $int) / log 2) + 0.5 );

    my $ratio = $interval2ratio{$int};
    return $self->_interval( $ratio )
        if $ratio;

    # Now let's detect...
    $int =~ /([dmPMA])([1-9]\d*)/
        or die "Wrong interval format";
    my ($type, $n) = ($1, $2);

    # handle flattened & sharpened intrevals
    $type eq 'd' 
        and return ($self->_interval("m$n") || $self->_interval("P$n"))-1;
    $type eq 'A' 
        and return ($self->_interval("M$n") || $self->_interval("P$n"))+1;

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

1;
