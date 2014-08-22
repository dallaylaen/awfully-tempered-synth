# Real sound with pitch etc.
# Compatible to raw_player whatever it is.

package My::Score::Sound;
use Moo;

has start => is => "rw" => required => 1;
has len   => is => "rw" => required => 1;
has pitch => is => "rw" => required => 1;
has vol   => is => "rw" => default => sub { 1 };

sub voltage {
    my $self = shift;

    return 10 ** ( $self->vol / 10 );
};

sub adjust_vol {
    my ($self, $by) = @_;

    $self->vol ( $self->vol + $by );
};

sub to_string {
    my $self = shift;

    return join " ", $self->start, $self->len, $self->pitch, $self->voltage;
};

sub harmonic {
    my ($self, %harm) = @_;

    my @out;
    while (my ($mult, $vol) = each %harm) {
        push @out, (ref $self)->new( %$self, 
            pitch => $self->pitch * $mult, vol => $self->vol + $vol );
    };
    return @out;
};

sub normalize_all {
    my ($class, $array) = @_;

    my $by = 1/$class->max_volume( $array );

    # factor back to dB # TODO inefficient!
    $by = 10 * log($by) / log 10;

    if ( $by < 0 ) {
        $_->adjust_vol( $by ) for @$array
    };
};

sub max_volume {
    my ($class, $array) = @_;

    my @pairs = map {
        [ $_->start, +$_->voltage ], [ $_->start+$_->len, -$_->voltage ];
    } @$array;

    @pairs = sort { $a->[0] <=> $b->[0] } @pairs;

    my $max = 0;
    my $current = 0;
    foreach (@pairs) {
        $current += $_->[1];
        $current > $max and $max = $current;
    };
    return $max;
};

1;
