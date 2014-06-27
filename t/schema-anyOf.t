#-*- mode: cperl -*-#
use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok('JSON::Schema::Naive') }

my $s = JSON::Schema::Naive->new;

$s->schema(
    {
        type       => "object",
        properties => {
            reason => {
                "anyOf" => [
                    { "type" => "string" },
                    {
                        "type"       => "object",
                        "properties" => {
                            "code" => {
                                "type"     => "integer",
                                "minimum"  => 100,
                                "maximum"  => 999,
                                "required" => 1
                            },
                            "message" => {
                                "type"     => "string",
                                "required" => 1
                            }
                        }
                    }
                ]
            }
        }
    }
);

ok( $s->validate( { reason => "one good reason" } ), "anyOf valid" );

ok(
    $s->validate(
        { reason => { code => 200, message => "another good reason" } }
    ),
    "anyOf valid"
);

exit;
