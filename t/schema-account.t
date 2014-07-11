#-*- mode: cperl -*-#
use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use utf8; use_ok('JSON::Schema::Naive') }

my $s = JSON::Schema::Naive->new;
$s->schema(
    {
        title      => "create account",
        type       => "object",
        properties => {
            account => {
                type        => "string",
                required    => 1,
                description => "account identifier",
                minLength   => 1,
                maxLength   => 255
            },
            is_admin => {
                type        => "boolean",
                default     => 0,
                description => "set `true` for administrative accounts"
            },
            disabled => {
                type    => "integer",
                minimum => 0,
                default => 0,
                description =>
"set to epoch time when account was/will be disabled; set to `0` to enable"
            },
            create_domain => {
                type => "boolean"
            }
        }
    }
);

#$JSON::Schema::Naive::DEBUG = 1;

ok(
    $s->validate(
        {
            'account'       => 'admin-guy@testing.com',
            'create_domain' => 1,
            'is_admin'      => 1
        }
    ),
    "full schema validate"
);

exit;
