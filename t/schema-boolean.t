#-*- mode: cperl -*-#
use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 6;

BEGIN { use_ok('JSON::Schema::Naive') }

package SomeJSON;

use overload '0+' => sub { ${$_[0]} }, '""' => sub { ${$_[0]} }, fallback => 1;

my $FALSE = bless \(my $false = 0), 'SomeJSON';
my $TRUE  = bless \(my $true  = 1), 'SomeJSON';

sub true  { $TRUE }
sub false { $FALSE }

package main;

my $s = JSON::Schema::Naive->new;

$s->true(sub { SomeJSON::true() });
$s->false(sub { SomeJSON::false() });

$s->schema(
    {
        type       => "object",
        properties => {
            is_admin => {
                type => "boolean",
                required => 1
            }
        }
    }
);

my $value = SomeJSON::true;

ok( JSON::Schema::Naive::TRUE, "true" );

ok( $s->validate( { is_admin => $value } ), "valid boolean" );

ok( ! $s->validate( { is_admin => undef } ), "invalid boolean" );

ok( $s->validate( { is_admin => !!1 } ), "valid boolean" );

ok( $s->validate( { is_admin => "true" } ), "valid boolean" );

exit;
