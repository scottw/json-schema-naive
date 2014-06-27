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
                type    => "string",
                pattern => '^\d{4}-\d{2}-\d{2}$'
            }
        },

        type       => "object",
        properties => {
            added => { '$ref' => "#/definitions/date" }
        }
    }
);

ok( $s->validate( { added => "2014-06-27" } ), "string regex validation" );

ok( !$s->validate( { added => "2014-06-27 12:23:33" } ),
    "string regex validation fail" );

like( ( $s->errors )[0], qr(does not match pattern), "invalid date" );

exit;
