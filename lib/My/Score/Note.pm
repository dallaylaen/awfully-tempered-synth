package My::Score::Note;
use Moo;

# tone is really an INTERVAL counted from tune's key.
has tone  => is => "rw" => required => 1;
has start => is => "rw" => default => sub { 0 };
has len   => is => "rw" => default => sub { 1 };
has vol   => is => "rw" => default => sub { 0 };
has oct   => is => "rw" => default => sub { 0 };
has rel   => is => "rw";
my $id;
has id    => is => "ro" => default => sub { ++$id };

sub clone {
    my ($self, %opt) = @_;
    return (ref $self)->new( %$self, %opt);
};

sub dump {
    my $self = shift;
    return join " ", "id=".$self->id, ($self->rel ? "rel=".$self->rel->id : "!_!"),
         map { "$_=".$self->$_ } qw(start len tone vol oct);
};

1;
