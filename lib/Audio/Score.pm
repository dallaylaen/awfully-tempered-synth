package Audio::Score;
use Moo;

use Audio::Play;
use Audio::Score::Chord;

has base => is => "rw";
has engine => is => "rw", default => sub { Audio::Play->new };
has cache => is => "rw", default => sub { {} };

has tone => is => "rw", default => sub { 440 }, 
        trigger => sub { shift->cache( {} ) };
has meter => is => "rw", default => sub { 4 };
has tempo => is => "rw", default => sub { 60 };
has vol => is => "rw", default => sub { 0 };

sub tack {
    my $self = shift;
    return 60 / $self->tempo;
};
sub tick {
    my $self = shift;
    return $self->tack / $self->meter;
};

has edge => is => "rw", default => sub { 0 };
has tack_edge => is => "rw", default => sub { 0 },
        trigger => sub { $_[0]->edge($_[1]) };

sub advance_tack {
    my $self = shift;

    my $edge = $self->tack_edge + $self->tack;
    $self->tack_edge($edge);
};

sub parse_line {
    my ($self, $line) = @_;

    $line =~ s/^\s+//;
    return if $line =~ /^#/;

    # keywords: set
    if ($line =~ /^set\s+(.*)$/) {
        return unless $1;
        my %opt = $1 =~ m/(\S+)/g;

        foreach my $method( qw(base meter tempo vol tone) ) {
            my $arg = delete $opt{$method};
            defined $arg or next;
            $self->$method($arg);
            warn "Set $method = $arg\n";
        };

        warn "Unknown values in set(): ".join ",", keys %opt
            if %opt;
        return;
    };

    # tack label
    $line =~ s/^--\s*// and $self->advance_tack;

    # tick label
    $line =~ s/^(\d(?:\.\d)?):\s*// 
        and $self->edge( $self->tack_edge + $self->tick * $1 );
    
    return unless $line =~ /\S/;

    # fianlly! parse chords
    my $chord = Audio::Score::Chord->new( $line =~ m,(\S+),g );
    $self->add_chord($chord);
};



sub add_chord {
    my ($self, $chord) = @_;

    foreach my $note ($chord->notes) {
        $self->engine->add_sound(
            pitch => $self->get_pitch( $note, $chord->oct ),
            vol => $self->vol + $chord->vol,
            start => $self->edge,
            len => $self->tick * $chord->len,
        );
    };
};

sub get_pitch {
    my ($self, $note, $oct) = @_;

    $oct and $note += $oct * $self->base;

    return $self->cache->{$note} ||= $self->tone * ( 2 ** ($note/$self->base) );
};

1;

