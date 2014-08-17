package Audio::Score::Chord;
use Moo;

has chord => is => "rw";
has vol => is => "rw" => default => sub { 0 };
has len => is => "rw" => default => sub { 1 };
has oct => is => "rw" => default => sub { 0 };
has wave => is => "rw";
has base => is => "ro";

sub notes {
    my $self = shift;

    return split /,/, $self->chord // '';
};

1;
