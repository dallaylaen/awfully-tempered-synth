# Apply specific sound parameters to tune
# TODO move instruments to raw_synth

package My::Score::Instrument;
use Moo;

use My::Score::Sound;

has harmonics => is => "rw" => default => sub {
    1 => 0
};

sub play_to_fd {
    my ($self, $fd, @tune) = @_;

    my @real_sounds = map { $self->play_sound( $_ ) } 
            map { $_->play } @tune;
    My::Score::Sound->normalize_all( \@real_sounds );
    @real_sounds = sort { $a->start <=> $b->start } @real_sounds;

    print $fd $_->to_string."\n" for @real_sounds;
};

sub play_sound {
    my ($self, $sound) = @_;

    return $sound->harmonic( %{ $self->harmonics } );
};

1;
