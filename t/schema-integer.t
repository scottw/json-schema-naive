#-*- mode: cperl -*-#
use strict;
use warnings;
use Test::More tests => 9;

BEGIN { use_ok('JSON::Schema::Naive') }

my $s = JSON::Schema::Naive->new;

$s->schema(
    {
        type       => "object",
        properties => {
            duration => {
                "type"     => "integer",
                "required" => 1
            }
        }
    }
);

ok( $s->validate( { duration => 100 } ), "integer validate" );
ok( !$s->validate( { duration => "fish" } ), "integer invalid" );
like( ( $s->errors )[0], qr('duration' is not an integer), "integer error" );

$s->schema(
    {
        type       => "object",
        properties => {
            duration => {
                type    => "integer",
                maximum => 999,
                minimum => 100
            }
        }
    }
);

ok( $s->validate( { duration => 200 } ), "valid integer" );

ok( !$s->validate( { duration => 90 } ), "integer too small" );
like(
    ( $s->errors )[0],
    qr('duration' cannot be less than 100),
    "too small error"
);

ok( !$s->validate( { duration => 1000 } ), "integer too large" );
like(
    ( $s->errors )[0],
    qr('duration' cannot be more than 999),
    "too large error"
);

exit;
