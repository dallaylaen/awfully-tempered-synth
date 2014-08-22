package My::Score::Note;
use Moo;

# tone is really an INTERVAL counted from tune's key.
has tone  => is => "rw" => required => 1;
has start => is => "rw" => default => sub { 0 };
has len   => is => "rw" => default => sub { 1 };
has vol   => is => "rw" => default => sub { 0 };
has oct   => is => "rw" => default => sub { 0 };

sub adjust {
    my ($self, $opt) = @_;

    return (ref $self)->new(
        tone  => $self->tone  + ($opt->{tone} // 0),
        start => $self->start + ($opt->{start} // 0),
        vol   => $self->vol   + ($opt->{vol} // 0),
        # only length is multiplied
        len   => $self->len   * ($opt->{len} // 1),
    );
};

1;
