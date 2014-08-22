# read file line by line
# make tune objects
# use set to setup them
# at the end feed to player

package My::Score::Parser;
use Moo;

use My::Score::Tune;
use My::Score::Instrument;

my %synth = (
    0.5 => -6,
    1 => 0,
    2 => -6,
    3 => -9,
    4 => -12,
    5 => -15,
    6 => -18,
);

# main tunes to play
has tune_list => is => "rw", default => sub { [] };
has instrument => is => "rw", default => sub {
    My::Score::Instrument->new( harmonics => \%synth );
};

sub last_tune {
    my $self = shift;

    $self->add_tune( My::Score::Tune->new )
        if (!@{ $self->tune_list });
    return $self->tune_list->[-1];
};

sub add_tune {
    my ($self, $tune) = @_;

    push @{ $self->tune_list }, $tune;
};

sub parse_line {
    my ($self, $line) = @_;

    $line =~ s/^\s+//;
    return if $line =~ /^#/;

    # keywords: set
    if ($line =~ /^set\s+(.*)$/) {
        return unless $1;
        my %opt = $1 =~ m/(\S+)/g;

        $self->add_tune( $self->last_tune->clone( %opt ) );

        return;
    };

    # tack label
    $line =~ s/^--\s*// and $self->last_tune->advance_tack;

    # tick label
    $line =~ s/^(\d(?:\.\d)?):\s*// 
        and $self->last_tune->set_tick( $1 );
    
    return unless $line =~ /\S/;

    # fianlly! parse chords
    my %opt = ( $line =~ m,(\S+),g );
    my @notes = split /,/, delete $opt{chord};

    $self->last_tune->add_chord(%opt, notes => \@notes);
};

sub play_to_fd {
    my ($self, $fd) = @_;

    $self->instrument->play_to_fd( $fd, @{ $self->tune_list } );
};

1;
