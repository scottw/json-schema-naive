#-*- mode: cperl -*-#
use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 11;

BEGIN { use_ok('JSON::Schema::Naive') }

package SomeJSON;

use overload '0+' => sub { ${$_[0]} }, '""' => sub { ${$_[0]} }, fallback => 1;

my $FALSE = bless \(my $false = 0), 'SomeJSON';
my $TRUE  = bless \(my $true  = 1), 'SomeJSON';

sub true  {$TRUE}
sub false {$FALSE}

package main;

my $s = JSON::Schema::Naive->new;
$s->true(sub  { SomeJSON::true() });
$s->false(sub { SomeJSON::false() });
$s->normalize(
    {
        boolean => sub {
            $_[0] = "truthy" if $_[0];
            $_[0] = "falsey" unless $_[0];
        }
    }
);

$s->schema(
    {
        type       => "object",
        properties => {is_admin => {type => "boolean", required => 1}}
    }
);

my $value = SomeJSON::true;

ok(JSON::Schema::Naive::TRUE, "true");

my $obj = {is_admin => $value};
ok($s->validate($obj), "valid boolean");
is($obj->{is_admin}, "truthy", "object normalized");

$obj = {is_admin => undef};
ok(!$s->validate($obj), "invalid boolean");
is($obj->{is_admin}, undef, "object not normalized");

$obj = {is_admin => !!1};
ok($s->validate($obj), "valid boolean");
is($obj->{is_admin}, "truthy", "object normalized");

$obj = {is_admin => !1};
ok($s->validate($obj), "valid boolean");
is($obj->{is_admin}, "falsey", "object normalized");

$obj = {is_admin => "true"};
ok(!$s->validate($obj), "invalid boolean");

exit;
