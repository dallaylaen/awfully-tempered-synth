package Audio::Play::Sound;
use Moo;

has pitch => is => "ro", required => 1;
has vol => is => "ro", default => sub {1};
has start => is => "ro", required => 1;
has len => is => "ro", required => 1;
has wave => is => "ro", default => sub { "sin" };

sub voltage {
    my $self = shift;
    return 10 ** ($self->vol / 10 );
};

sub end {
    my $self = shift;
    return $self->start + $self->len;
};

sub harmonic {
    my ($self, %harm) = @_;

    return map { (ref $self)->new(
        start  => $self->start,
        len    => $self->len,
        wave   => $self->wave,
        pitch  => $self->pitch * $_,
        vol    => $self->vol + $harm{$_},
    ) } keys %harm;
};

sub get_synth {
    my $self = shift;
    return $self->len, $self->wave, $self->pitch;
};
sub get_delay {
    my $self = shift;
    return $self->start;
};
sub get_remix {
    my $self = shift;
    return "p".$self->vol;
};

1;
