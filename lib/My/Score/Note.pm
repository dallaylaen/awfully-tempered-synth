package My::Score::Note;
use Moo;

# tone is really an INTERVAL counted from tune's key.
has tone  => is => "rw" => required => 1;
has start => is => "rw" => default => sub { 0 };
has len   => is => "rw" => default => sub { 1 };
has vol   => is => "rw" => default => sub { 0 };
has oct   => is => "rw" => default => sub { 0 };
has rel   => is => "rw";

sub clone {
    my ($self, %opt) = @_;
    return (ref $self)->new( %$self, %opt);
};

1;
