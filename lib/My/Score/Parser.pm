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
    $line =~ s/^(\d+(?:\.\d+)?):\s*// 
        and $self->last_tune->set_tick( $1 );
    
    return unless $line =~ /\S/;

    # fianlly! parse chords
    my %opt = ( $line =~ m,(\S+),g );
    my $seq = defined $opt{seq};
    my $notes = delete $opt{seq} // delete $opt{chord};
    defined $notes or die "No notes found in chord";

    $self->last_tune->add_notes( 
        notes => $self->parse_chord($notes, %opt),
        seq => $seq,
    );
};

sub parse_chord {
    my ($self, $str, %opt) = @_;

    $opt{oct} //= 0;

    my @notes;
    my $root;
    foreach (split /\s*[\s,]\s*/, $str) {
        my ($add_mode, $oct, $tone, $abs_note) 
            = /^([+=]?)(?:(-?\d+)?:)?(([A-G][b#]?)|.*)$/
                or die "Bad note spec $_";

        $abs_note and $add_mode 
            and die "Cannot have +/= and note at once in $_";

        $oct = $opt{oct} + ($oct || 0);
        $add_mode ||= '';

        my $setroot;
        my $rel;
        if ($add_mode eq '=' or $abs_note or !@notes) {
            $setroot = 1;
        } else {
            $rel = $add_mode eq '+' ? $notes[-1] : $root;
        };

        my $note = My::Score::Note->new(
            %opt, oct => $oct, tone => $tone, rel => $rel
        );
        push @notes, $note;
        $root = $note if $setroot;
    };
    return \@notes;
};

sub play_to_fd {
    my ($self, $fd) = @_;

    $self->instrument->play_to_fd( $fd, @{ $self->tune_list } );
};

sub dump {
    my ($self, $prefix) = @_;
    $prefix //= '';

    return "${prefix}DUMP MUSIC\n"
        .(join "\n", map { "$prefix\t".$_->dump } @{ $self->tune_list })
        ."${prefix}END DUMP MUSIC\n";
};

1;
