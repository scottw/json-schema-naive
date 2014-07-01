#-*- mode: cperl -*-#
use strict;
use warnings;
use Test::More tests => 4;

BEGIN { use_ok('JSON::Schema::Naive') }

my $s = JSON::Schema::Naive->new;

$s->schema(
    {
        definitions => {
            date => {
                type    => "string"
            }
        },

        type       => "object",
        properties => {
            added => { '$ref' => "#/definitions/date" }
        }
    }
);

ok( $s->validate( { added => "the date: 2014-06-27" } ), "string validation" );

ok( !$s->validate( { added => undef } ),
    "string validation fail" );

like( ( $s->errors )[0], qr(not a string type), "invalid date" );

exit;
