#-*- mode: cperl -*-#
use strict;
use warnings;
use Test::More tests => 10;

BEGIN { use_ok('JSON::Schema::Naive') }

my $s = JSON::Schema::Naive->new;

$s->schema(
    {
        definitions => {
            date => {
                type => "string"
            }
        },

        type       => "object",
        properties => {
            account => {
                type      => "string",
                minLength => 5,
                maxLength => 16
            },
            added => { '$ref' => "#/definitions/date" }
        }
    }
);

#$JSON::Schema::Naive::DEBUG = 1;

ok( $s->validate( { account => "foooo", added => "the date: 2014-06-27" } ),
    "string validation" );

ok( !$s->validate( { added => undef } ), "string validation fail" );

like( ( $s->errors )[0], qr(not a string type), "invalid date" );

ok( $s->validate( { account => "abcde", added => "yesterday" } ),
    "string length check" );
ok( $s->validate( { account => "abcdeabcdeabcdea", added => "yesterday" } ),
    "string length check" );
ok( !$s->validate( { account => "abcd", added => "today" } ),
    "string length check fail" );
like( ( $s->errors )[0], qr(cannot be less than 5 ch), "min length error" );

ok( !$s->validate( { account => "abcdeabcdeabcdeab", added => 'today' } ),
    "string length check fail" );
like( ( $s->errors )[0], qr(cannot be more than 16 ch), "max length error" );

exit;
