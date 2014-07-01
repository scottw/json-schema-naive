#-*- mode: cperl -*-#
use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok('JSON::Schema::Naive') }

my $s = JSON::Schema::Naive->new;

$s->schema(
    {
        "title"      => "create auth-token",
        "type"       => "object",
        "properties" => {
            "duration" => {
                "type"    => "integer",
                "default" => 86400,
                "minimum" => 0,
                "maximum" => 86400,
                "description" =>
                  "how long (in seconds) the auth-token will last"
            }
        }
    }
);

my $params = {};

ok( $s->validate( $params ), "empty object" );

is( $params->{duration}, 86400, "default set" );

exit;
