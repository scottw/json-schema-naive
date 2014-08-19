#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';

my $oneOf = sub {
    my @err = ();

    1 == grep {
        @err = is_valid($_);
        ! scalar @err
    } @_;
};

my $anyOf = sub {
    my @err = ();

    !! grep {
        @err = is_valid($_);
        ! scalar @err
    } @_;
};

my $allOf = sub {
    ! map {
        is_valid($_)
    } @_;
};


for (0..3) {
    my @valid = (((1) x $_), ((0) x (3-$_)));
    say "VALID: " . join ', ' => @valid;
    say "    one of: " . $oneOf->(@valid);
    say "    any of: " . $anyOf->(@valid);
    say "    all of: " . $allOf->(@valid);
    say "";
}


exit;

sub is_valid {
    shift() ? () : (1);
}
