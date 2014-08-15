#-*- mode: cperl -*-#
use strict;
use warnings;
use Test::More tests => 14;

BEGIN { use_ok('JSON::Schema::Naive') }

my $s = JSON::Schema::Naive->new;

$s->schema(
    {
        type       => "object",
        properties => {
            reason => {
                type       => "object",
                required   => 1,
                properties => {
                    code => {
                        type     => "integer",
                        minimum  => 100,
                        maximum  => 999,
                        required => 1
                    },
                    message => {
                        type     => "string",
                        required => 1
                    },
                    blanket => {
                        type => "boolean"
                    }
                }
            }
        }
    }
);

ok( $s->validate( { reason => { code => 200, message => "fooey" } } ),
    "object validation" );

ok( !$s->validate( { horse => "fly" } ), "object invalid" );
like( ( $s->errors )[0], qr('reason' is required), "missing required field" );
like( ( $s->errors )[-1], qr(Unrecognized properties: horse)i, "unrecognized parameter" );

{
    ok( !$s->validate( { reason => { code => 123, message => "sorry" }, horse => "fly" } ), "object invalid" );
    like( ( $s->errors )[-1], qr(Unrecognized properties: horse)i, "unrecognized parameter" );

    local $JSON::Schema::Naive::ERROR_UNRECOGNIZED_PARAMS;
    ok( $s->validate( { reason => { code => 123, message => "sorry" }, horse => "fly" } ), "object invalid" );
    like( ( $s->warnings )[-1], qr(Unrecognized properties: horse)i, "unrecognized parameter" );
}

#$JSON::Schema::Naive::DEBUG=1;

ok( !$s->validate( { reason => "glue" } ), "object invalid" );
like( ( $s->errors )[0], qr('reason' is not an object), "invalid type" );

ok( !$s->validate( { reason => { code => "string", message => ["foo"] } } ),
    "object invalid" );
is( scalar( $s->errors ), 2, "error list" );

like(
    ( $s->errors )[0],
    qr((?:'code' is not an integer|'message' is not a string)),
    "invalid object errors"
);

exit;
