#-*- mode: cperl -*-#
use strict;
use warnings;
use Test::More tests => 6;

BEGIN { use_ok('JSON::Schema::Naive') }

my $s = JSON::Schema::Naive->new;

$s->schema(
    {
        type  => "object",
        query => {
            beef => {
                type     => "integer",
                required => 1,
                minimum  => 5,
                maximum  => 9
            },
            cake => {
                type     => "string",
                required => 1
            },
            bucket => {
                type => "string"
            }
        }
    }
);

# $JSON::Schema::Naive::DEBUG=1;

ok( $s->validate( { beef => 5, cake => "cake" } ), "query valid" );

ok( ! $s->validate( { beef => 3, bucket => "burp" } ), "query invalid" );
like( (sort $s->errors)[0], qr('beef' cannot be less than), "integer minimum" );
like( (sort $s->errors)[1], qr('cake' is required), "required" );

$s->schema(
    {
        type  => "object",
        query => {
            bucket => {
                type => "string"
            }
        }
    }
);

# $JSON::Schema::Naive::DEBUG=1;

ok( $s->validate( { bucket => "cards" } ), "query valid" );

exit;
