#-*- mode: cperl -*-#
use strict;
use warnings;
use Test::More tests => 10;

BEGIN { use_ok('JSON::Schema::Naive') }

my $s = JSON::Schema::Naive->new;

$s->schema(
    {
        type       => "object",
        properties => {
            network_ids => {
                type        => "array",
                required    => 1,
                minItems    => 0,
                uniqueItems => 1,
                items       => {
                    type    => "string",
                    pattern => '^[\w-]{6}$'
                }
            }
        }
    }
);

ok( ! $s->validate( { horse => "stew" } ),
    "missing property" );

ok( $s->validate( { network_ids => [ ] } ),
    "empty array validation" );

ok( $s->validate( { network_ids => ['abcdef', 'bcdefg'] } ),
    "array validation" );

ok( ! $s->validate( { network_ids => "boo" } ),
    "array invalid" );
like( ( $s->errors )[0], qr('network_ids' is not an array), "array type error" );

ok( ! $s->validate( { network_ids => ['abcdef', 'abcdef', 'bcdefg'] } ),
    "uniqueness requirement failed" );
like( ( $s->errors )[0], qr('network_ids' must contain unique items), "uniqueness error" );

#$JSON::Schema::Naive::DEBUG = 1;

ok( ! $s->validate( { network_ids => ['abcdef', 'abcde', 'bcdefg'] } ),
    "pattern constraint failed" );
like( ( $s->errors )[0], qr('network_ids' does not match pattern), "pattern error" );

#$JSON::Schema::Naive::DEBUG=1;

exit;
