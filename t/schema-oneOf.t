#-*- mode: cperl -*-#
use strict;
use warnings;
use Test::More tests => 8;

BEGIN { use_ok('JSON::Schema::Naive') }

my $s = JSON::Schema::Naive->new;

$s->schema(
    {
        type       => "object",
        properties => {
            reason => {
                required => 1,
                "oneOf" => [
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

ok( $s->validate( { reason => "one good reason" } ), "oneOf valid" );

ok(
    $s->validate(
        { reason => { code => 200, message => "another good reason" } }
    ),
    "oneOf valid"
);

ok( ! $s->validate( { } ), "oneOf invalid" );

## another style: validation by reference
$s->schema(
    {
        type       => "object",
        properties => {
            volume_id => {
                type => "string",
            },
            by_instance => {
                type => "boolean"
            },
            domain_id => {
                type => "string"
            }
        },
        oneOf => [
            { type => "object", required => ["volume_id"] },
            { type => "object", required => ["by_instance"] },
            { type => "object", required => ["domain_id"] }
        ]
    }
);

ok( $s->validate( { volume_id => "some-volume" } ), "oneOf valid" );

ok( $s->validate( { by_instance => 1 } ), "oneOf valid" );

ok( ! $s->validate( { domain_id => "some-domain", by_instance => 0 } ), "oneOf invalid" );
like( ($s->errors)[0], qr(oneOf failed), "oneOf error" );

exit;
