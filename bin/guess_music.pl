#!/usr/bin/perl -w
 
use strict;
use Data::Dumper;

my %notes = (
    do => 1,
    re => "9/8",
    mib => "6/5",
    mi => "5/4",
    fa => "4/3",
    sol => "3/2",
    la => "5/3",
    si => "15/8",
    DO => 2,
);

 
my $besterr = 1000;
foreach my $i ( 5..1200 ) {
    my ($err, $notes) = find_all( 2**(1/$i), qw(1 9/8 6/5 5/4 4/3 3/2 5/3 15/8 2) );
    next if $err > 1.3 * $besterr;
    next unless has_seconds($notes);
     
    $besterr = $err if $err < $besterr;
     
    print "2^$i: $err: \n".display_notes($notes)."\n";
 
};
 
 
 
 
sub find_all {
    my ($base, @ratios) = @_;
     
    my $maxerr = 0;
    my %notes;
    foreach (@ratios) {
        my ($pow, $err) = ratio_diff( $base, $_ );
        $notes{$_} = $pow;
        if ($err > $maxerr) {
            $maxerr = $err;
        };
    };
    return ( $maxerr, \%notes );
};


sub has_seconds {
    my $hash = shift;

    my $bsec = $hash->{"9/8"};
    my $msec = $hash->{2} - $hash->{"15/8"};

    return
        interval( $hash, "do", "re" ) == $bsec &&
        interval( $hash, "re", "mi" ) == $bsec &&
        interval( $hash, "fa", "sol" ) == $bsec &&
        interval( $hash, "sol", "la" ) == $bsec &&
        interval( $hash, "la", "si" ) == $bsec &&
        interval( $hash, "mi", "fa" ) == $msec &&
        interval( $hash, "re", "mib" ) == $msec &&
        interval( $hash, "si", "DO" ) == $msec;
}; 

sub interval {
    my ($hash, $n1, $n2) = @_;

    $n1 = $notes{$n1} || $n1;
    $n2 = $notes{$n2} || $n2;

#    warn "$n1 - $n2";

    return $hash->{$n2} - $hash->{$n1};
};
 
sub ratio_diff {
    my ($base, $ratio) = @_;
     
    $ratio =~ m{(\d+)/(\d+)}
    and $ratio = $1/$2;
     
    my $pow = int ((log ($ratio) / log ($base)) + 0.5);
    my $appr = $base ** $pow;
     
    my $err = abs ($ratio - $appr) / abs ($ratio);
     
    return ($pow, $err);
};

sub display_notes {
    my $hash = shift;

    my @out;
    foreach (sort { $hash->{$a} <=> $hash->{$b} } keys %$hash) {
         push @out, "$_: $hash->{$_}";
    };
    return join ", ", @out;
};
