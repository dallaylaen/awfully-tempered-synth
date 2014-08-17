package Audio::Play;

use Moo;
use File::Temp qw(tempfile);
use FindBin qw($Bin);

use Audio::Play::Sound;

has sounds => is => ro => default => sub { [] };

sub raw_player {
    my ($self, %opt) = @_;

    if (defined $opt{record}) {
        return sprintf "%s/%s -r 44100 -v %f | sox -t raw %s -r 44100 - '%s'",
            $Bin, "../csynth/raw_player", 0.9/$self->max_volume,
            "-e signed -b 32 -r 44100 -c 1", $opt{record};
    };

    return sprintf "%s/../csynth/raw_player -p -v %f", $Bin, 0.9/$self->max_volume;
};

sub add_sound {
    my ($self, %opt) = @_;

    # warn join ",", keys %opt;

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


sub pipe_sound {
    my ($self, $fd) = @_;

    my @snd = sort { $a->start <=> $b->start } @{ $self->sounds };

    @snd = map { $_, $_->harmonic( 0.5 => -6, 2=>-6, 3=>-12, 4=>-18, 5=>-24, 6=>-30) } @snd;
    
    foreach (@snd) {
        printf $fd "%0.18f %0.18f %0.18f %0.18f\n", 
            $_->start, $_->len, $_->pitch, $_->voltage;
    };
    
};

sub run {
    my ($self, %opt) = @_;

    my $pid = open ( my $fd, "|-", $self->raw_player(%opt) );
    die "Popen failed: $!" unless $pid;

    $self->pipe_sound($fd);
    close ($fd);

    waitpid( $pid, 0 );
    return $?;
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
