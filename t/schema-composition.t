#-*- mode: cperl -*-#
use strict;
use warnings;
use Test::More tests => 8;
use Data::Dumper;

BEGIN { use utf8; use_ok('JSON::Schema::Naive') }

my $s = JSON::Schema::Naive->new;
$s->schema(
    {
        definitions => {
            reason => {
                anyOf => [
                    { type => "string" },
                    {
                        type       => "object",
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
                            }
                        }
                    }
                ]
            },

            date => {
                type     => "string",
                pattern  => '^\d{4}-\d{2}-\d{2}$',
                required => 1
            }
        },

        type       => "object",
        properties => {
            error_reason => { '$ref' => "#/definitions/reason" },
            added        => { '$ref' => "#/definitions/date" }
        }
    }
);

ok( $s->validate( { error_reason => "some reason", added => "2014-06-27" } ),
    "composition validate" );

#$JSON::Schema::Naive::DEBUG = 1;

ok(
    $s->validate(
        {
            error_reason => { code => 123, message => "dink" },
            added        => "2014-06-27"
        }
    ),
    "composition validate"
);

ok( !$s->validate( { error_reason => "some reason" } ),
    "composition validate error" );

like( ( $s->errors )[0], qr('added' is required), "date required" );

$s->schema(
    {
        definitions => {
            http_reason => {
                type       => "object",
                properties => {
                    code => {
                        type    => "integer",
                        minimum => 100,
                        maximum => 999
                    },
                    message => {
                        type => "string"
                    }
                }
            }
        },

        type       => "object",
        properties => {
            account => {
                type => "string"
            },
            disabled => {
                type    => "integer",
                minimum => 0
            },
            disabled_reason => {
                oneOf => [
                    { '$ref' => "#/definitions/http_reason" },
                    {
                        type      => "string",
                        minLength => 0,
                        maxLength => 50
                    }
                ]
            }
        }
    }
);

my $obj = {
    account         => "foo",
    disabled        => 1,
    disabled_reason => { code => 402, message => "Need more money" }
};

#$JSON::Schema::Naive::DEBUG = 1;

ok( $s->validate($obj), "object composition" );
is( ref($obj->{disabled_reason}), "HASH", "object intact" );
is( $obj->{disabled_reason}->{code}, 402, "object intact" );

exit;
