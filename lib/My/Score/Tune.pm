# Tune is a collection of notes. Tune may be converted to real sounds,
#    or incorporated into other tune

package My::Score::Tune;
use Moo;

use My::Score::Note;
use My::Score::Sound;
use My::Score::Tet;

has notes  => is => "rw", default => sub { [] };

# TODO tuning/base is done via ass, REWRITE
has tuning => is => "rw", lazy => 1, default => sub {
    My::Score::Tet->tet($_[0]->base);
};
has base   => is => "rw", default => sub { 12 }, trigger => sub {
    my ($self, $base) = @_;
    $self->tuning( My::Score::Tet->tet($base) );
};

has vol    => is => "rw", default => sub{ 0 };
has start  => is => "rw", default => sub{ 0 };
has tone   => is => "rw", default => sub{ 440 };
has meter  => is => "rw", default => sub { 4 };
has tempo  => is => "rw", default => sub { 60 };

has edge   => is => "rw", default => sub { 0 };
has tack_edge => is => "rw", default => sub { 0 },
        trigger => sub { $_[0]->edge($_[1]) };

sub advance_tack {
    my $self = shift;

    my $edge = $self->tack_edge + $self->meter;
    $self->tack_edge($edge);
};

sub set_tick {
    my ($self, $delay) = @_;

    $self->edge( $self->tack_edge + $delay );
};

sub tick_len {
    my $self = shift;

    return 60 / ($self->meter * $self->tempo);
};

sub add_chord {
    my ($self, %opt) = @_;

    my $notes = delete $opt{notes};
    foreach (@$notes) {
        # TODO think how to add notes with vol/len adjustment
        push @{ $self->notes }, My::Score::Note->new(
            %opt, tone => $_, start => $self->edge );
    };
};

sub make_sound {
    my ($self, $note) = @_;

    # TODO note start/len will be nonlinear when smooth speedup is implemented
    return My::Score::Sound->new(
        start => $note->start * $self->tick_len + $self->start,
        len   => $note->len   * $self->tick_len,
        vol   => $self->vol + $note->vol,
        pitch => $self->tone  * 2**$note->oct * $self->tuning->pitch( 
            $note->tone =~ /^\d+$/
                ? $note->tone 
                : $self->tuning->interval( $note->tone )),
    );
};

sub play {
    my $self = shift;

    return map { $self->make_sound( $_ ) } @{ $self->notes };
};

sub clone {
    my ($self, %opt) = @_;

    $opt{start} //= $self->edge;
    $opt{edge}  //= 0;
    $opt{tack_edge} //= $self->tack_edge - $self->edge; # negative

    return (ref $self)->new( %$self, %opt, notes => [] );
};

1;
