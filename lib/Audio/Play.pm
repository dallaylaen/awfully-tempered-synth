package Audio::Play;

use Moo;
use File::Temp qw(tempfile);

use Audio::Play::Sound;

has sounds => is => ro => default => sub { [] };

sub add_sound {
    my ($self, %opt) = @_;

    warn join ",", keys %opt;

    push @{ $self->sounds }, Audio::Play::Sound->new( %opt );
};

sub get_sounds {
    my $self = shift;

    my $snd = $self->sounds;

    my $lastends = 0;
    foreach (@$snd) {
        $_->end > $lastends and $lastends = $_->end;
    };
    my $last = Audio::Play::Sound->new( vol => -9**9**9, start => 0, len => $lastends, pitch => 50);

    return $last, @$snd;
};

sub run {
    my $self = shift;

    return unless $self->get_sounds;

    my (undef, $fname) = tempfile ( CLEANUP => 1, SUFFIX => ".wav" );

    system "sox", "-n", $fname, # channels => 1, 
            $self->make_arg;
    system "play", $fname;
    unlink $fname;
    # TODO handle result
};

sub make_arg {
    my $self = shift;

    my @sounds = $self->get_sounds;
    return unless @sounds;

    my @synth = map { $_->get_synth } @sounds;
    my @delay = map { $_->get_delay } @sounds;
    my $i;
    my @remix = map { ++$i. $_->get_remix } @sounds;
    $remix[0] = "1v0";
    my $remix_join = join ",", @remix;

    my $gain = 1/$self->max_volume;
    
    return (
        synth => @synth,
        delay => @delay => remix => $remix_join => vol => $gain
    );
};

sub max_volume {
    my $self = shift;

    my @pairs = map {
        [ $_->start, +$_->voltage ], [ $_->start+$_->len, -$_->voltage ];
    } $self->get_sounds;

    @pairs = sort { $a->[0] <=> $b->[0] } @pairs;

    my $max = 0;
    my $current = 0;
    foreach (@pairs) {
        $current += $_->[1];
        $current > $max and $max = $current;
    };
    return $max;
};

1;
