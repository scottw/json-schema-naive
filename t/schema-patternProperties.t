#-*- mode: cperl -*-#
use strict;
use warnings;
use Test::More tests => 7;

BEGIN { use_ok('JSON::Schema::Naive') }

my $s = JSON::Schema::Naive->new;

$s->schema(
    {
        type       => "object",
        properties => {
            'bro-seph' => {
                type => "string",
                required => 1
            }
        },
        patternProperties => {
            "^foo" => {
                type        => "string",
                required    => 1,
                pattern     => "^bar",
                description => "foo.*/bar.* key/value pair"
            }
        }
    }
);

ok( $s->validate( { 'bro-seph' => 'me', foo => "bar" } ),
    "pattern property validation" );

ok( $s->validate( { 'bro-seph' => 'me', foots => "barfage" } ),
    "pattern property validation" );

ok( !$s->validate( { 'bro-seph' => 'me', foo => "baaar" } ),
    "pattern property failed" );
like( ($s->errors)[0], qr(does not match pattern), "pattern property error" );

ok( !$s->validate( { 'bro-seph' => 'me', fo => "bar" } ),
    "pattern property failed" );
like( ($s->errors)[1], qr(unrecognized properties: fo\b)i, "pattern property error" );

exit;
