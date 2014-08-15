package JSON::Schema::Naive;

use 5.016001;
use strict;
use warnings;
use utf8;
use feature 'say';
use Term::ANSIColor;
use Data::Dumper;
use Storable 'dclone';

our $VERSION                   = '0.01';
our $DEBUG                     = 0;
our $COLORED                   = 1;
our $ERROR_UNRECOGNIZED_PARAMS = 1;

use constant TRUE  => !!1;
use constant FALSE => !1;

sub new {
    my $class = shift;
    my $self  = {};
    my %args  = @_;

    $self->{_errors}   = [];
    $self->{_warnings} = [];
    $self->{_schema}   = $args{schema};
    $self->{_true}     = $args{true};
    $self->{_false}    = $args{false};

    bless $self, $class;
    return $self;
}

sub warning {
    push @{shift->{_warnings}}, @_;
}

sub warnings {
    return @{shift->{_warnings}};
}

sub error {
    push @{shift->{_errors}}, @_;
}

sub errors {
    return @{shift->{_errors}};
}

sub reset {
    my $self = shift;

    $self->{_errors}   = [];
    $self->{_warnings} = [];
}

sub true {
    my $self = shift;

    if (@_) {
        $self->{_true} = shift;
    }

    return ref $self->{_true} eq 'CODE' ? $self->{_true}->() : undef;
}

sub false {
    my $self = shift;

    if (@_) {
        $self->{_false} = shift;
    }

    return ref $self->{_false} eq 'CODE' ? $self->{_false}->() : undef;
}

sub schema {
    my $self = shift;

    if (@_) {
        $self->{_schema} = shift;
    }

    return $self->{_schema};
}

sub validate {
    my $self = shift;
    my $obj  = pop;

    $self->reset;

    $self->schema(shift) if @_;

    unless (ref $self->schema) {
        $self->error("No schema set; set with \$obj->schema()");
        return;
    }

    ## make a deep copy of the object we can tamper with; we promise
    ## not to touch $obj except to set a default value where defined
    !$self->error(
        $self->validate_type('' => $self->schema, $obj => dclone($obj)));
}

sub validate_type {
    my $self      = shift;
    my $name      = shift;
    my $subschema = shift;
    my $object    = shift;    ## original object
    my $params    = shift;    ## copy of object for messing with

    if ($subschema->{type}) {
        if ($subschema->{type} eq 'object') {
            return $self->validate_object($name => $subschema, $object,
                $params);
        }

        if ($subschema->{type} eq 'array') {
            return $self->validate_array($name => $subschema, $object, $params);
        }

        if ($subschema->{type} eq 'integer') {
            return $self->validate_integer($name => $subschema, $object,
                $params);
        }

        if ($subschema->{type} eq 'string') {
            return $self->validate_string($name => $subschema, $object,
                $params);
        }

        if ($subschema->{type} eq 'boolean') {
            return $self->validate_boolean($name => $subschema, $object,
                $params);
        }
    }

    return ();
}

sub validate_object {
    my $self   = shift;
    my $name   = shift;
    my $schema = shift;
    my $object = shift;
    my $params = shift;

    unless ($schema->{type} eq 'object') {
        return ("schema is not an object");
    }

    unless (ref $params eq 'HASH') {
        return "Parameter '$name' is not an object";
    }

    my @errors   = ();

    ## http://json-schema.org/latest/json-schema-validation.html#anchor64

    my $query = $schema->{query} || {};
    for my $prop (keys %$query) {
        push @errors,
          $self->validate_property($prop => $query->{$prop}, $object, $params);
    }

    my $properties = $schema->{properties} || {};
    for my $prop (keys %$properties) {
        push @errors,
          $self->validate_property(
            $prop => $properties->{$prop},
            $object, $params
          );
    }

    ## see if any of the remaining properties match a pattern
    my $patternProperties = $schema->{patternProperties} || {};
    for my $prop (keys %$params) {
        for my $pattern (keys %$patternProperties) {
            if ($prop =~ qr($pattern)) {
                push @errors,
                  $self->validate_property(
                    $prop => $patternProperties->{$pattern},
                    $object, $params
                  );
            }
        }
    }

    ## if $params still has keys, we didn't validate everything--error
    if (my @props = keys %$params) {
        push @{$ERROR_UNRECOGNIZED_PARAMS ? \@errors : $self->{_warnings}},
          "Incoming parameters: " . Dumper($params);
        push @{$ERROR_UNRECOGNIZED_PARAMS ? \@errors : $self->{_warnings}},
          "Unrecognized properties: " . join ", " => @props;
    }

    return @errors;
}

sub validate_array {
    my $self   = shift;
    my $name   = shift;
    my $schema = shift;
    my $object = shift;
    my $params = shift;

    unless ($schema->{type} eq 'array') {
        return "schema is not an array";
    }

    unless (ref $params eq 'ARRAY') {
        return "Parameter '$name' is not an array";
    }

    my @errors = ();

    ## FIXME: we also want to do tuple validation someday:
    ## https://spacetelescope.github.io/understanding-json-schema/reference/array.html

    ## list validation
    my $item = $schema->{items} || {};

    my %uniq = ();
    for my $param (@$params) {
        $uniq{$param}++ unless ref $param;
        push @errors, $self->validate_type($name => $item, $object, $param);
    }

    ## uniqueness check: if items is an array, we can't unique it; if
    ## the item type is an object we can't unique it
    if ($schema->{uniqueItems} and ref $item eq 'HASH' and keys %uniq) {
        if (scalar keys %uniq < scalar @$params) {
            push @errors, "Parameter '$name' must contain unique items";
        }
    }

    return @errors;
}

sub validate_property {
    my $self      = shift;
    my $name      = shift;    ## the name of our property
    my $subschema = shift;    ## the sub-schema for this property
    my $object    = shift;    ## the original object
    my $params    = shift;    ## object copy for messing with
    my $combine
      = shift;    ## indicates combinator--only delete parameter on success

    $self->debug(
        "Validating property [$name] against params " . Dumper($params));

    $self->debug(
        "Schema property '$name' is defined as: " . Dumper($subschema));

    $self->debug("Incoming object: " . Dumper($object));

    unless (ref $params) {
        return "Parameter '$name' is not an object type";
    }

    if (exists $subschema->{'$ref'}) {
        my $ptr  = delete $subschema->{'$ref'};
        my @path = grep {$_} split /\// => $ptr;
        my $doc  = shift @path || '';              ## normally just '#'
        ## FIXME: fetch/load the document otherwise

        if ($doc eq '#') {                         ## this document
            my $node = $self->{_schema};  ## refer to elsewhere in this document
            do {
                my $next = shift @path;
                $node = $node->{$next};    ## FIXME: check for null pointers
            } while @path;

            ## merge, not clobber
            $subschema->{$_} = $node->{$_} for keys %$node;
        }
    }

    if (!exists $object->{$name}) {

        if (exists $subschema->{default}) {
            $object->{$name} = $subschema->{default};
            $self->debug("Parameter $name using default: "
                  . (
                    defined $object->{$name} ? $object->{$name} : "(undefined)")
            );
            return;
        }

        if ($subschema->{required}) {
            return "Parameter '$name' is required";
        }

        return;    ## nothing to validate
    }

    ## not implemented!
    if (exists $subschema->{oneOf} and !exists $subschema->{anyOf}) {
        warn "oneOf combinator not implemented; using anyOf instead.\n";
        $subschema->{anyOf} = delete $subschema->{oneOf};
    }

    if (exists $subschema->{anyOf}) {
        $self->debug(
                "Checking if anyOf condition for '$name' is satisfied (object: "
              . Dumper($object)
              . ")");

        my @err   = ();
        my $anyOf = grep {
            $self->debug("anyOf condition '$name' against " . Dumper($params));
            @err = $self->validate_property(
                $name => $_,
                $object, $params, my $combine = 1
            );
            !scalar @err
        } @{$subschema->{anyOf}};

        if ($anyOf) {
            $self->debug("anyOf condition is satisfied");
        }
        else {
            $self->debug("anyOf condition failed:\n\t" . join("\n\t", @err));
        }

        return () if $anyOf;
        return ("anyOf condition not satisfied for '$name'");
    }

    if (exists $subschema->{allOf}) {
        $self->debug(
                "Checking of allOf condition for '$name' is satisfied (object: "
              . Dumper($object)
              . ")");

        my $allOf = !map {
            $self->validate_property(
                $name => $_,
                $object, $params, my $combine = 1
              )
        } @{$subschema->{allOf}};

        if ($allOf) {
            $self->debug("allOf condition is satisfied");
        }

        return () if $allOf;
        return ("allOf condition not satisfied for '$name'");
    }

    my @err = $self->validate_type(
        $name => $subschema,
        $object->{$name}, $params->{$name}
    );

    if (!scalar @err or !$combine) {
        $self->debug("Removing '$name' from parameters");
        delete $params->{$name};
    }

    $self->debug("After property validation, object: " . Dumper($object));

    return @err;
}

sub validate_integer {
    my $self   = shift;
    my $name   = shift;
    my $schema = shift;
    my $object = shift;
    my $params = shift;
    my $param  = (ref $params eq 'HASH' ? $params->{$name} : $params);

    if (ref $param or !defined $param) {
        return "Parameter '$name' is not an integer type";
    }

    if ($param !~ /^\d+$/) {
        return "Parameter '$name' is not an integer";
    }

    if (exists $schema->{minimum} and $param < $schema->{minimum}) {
        return "Parameter '$name' cannot be less than " . $schema->{minimum};
    }

    if (exists $schema->{maximum} and $param > $schema->{maximum}) {
        return "Parameter '$name' cannot be more than " . $schema->{maximum};
    }

    $self->debug("$param is a valid integer");
    return ();
}

sub validate_string {
    my $self   = shift;
    my $name   = shift;
    my $schema = shift;
    my $object = shift;
    my $params = shift;
    my $param  = (ref $params eq 'HASH' ? $params->{$name} : $params);

    if (ref $param or !defined $param) {
        return "Parameter '$name' is not a string type";
    }

    if (exists $schema->{minLength} and length $param < $schema->{minLength}) {
        return
            "Parameter '$name' cannot be less than "
          . $schema->{minLength}
          . " characters";
    }

    if (exists $schema->{maxLength} and length $param > $schema->{maxLength}) {
        return
            "Parameter '$name' cannot be more than "
          . $schema->{maxLength}
          . " characters";
    }

    if (exists $schema->{pattern} and $param !~ $schema->{pattern}) {
        ## FIXME: look first at $schema->{errors}->{pattern}, then $schema->{error}, then default
        return ($schema->{error}
            ? $schema->{error}
            : "Parameter '$name' does not match pattern " . $schema->{pattern});
    }

    $self->debug("$param is a valid string");
    return ();
}

sub validate_boolean {
    my $self   = shift;
    my $name   = shift;
    my $schema = shift;
    my $object = shift;
    my $params = shift;
    my $param  = (ref $params eq 'HASH' ? $params->{$name} : $params);

    if (!defined $param) {
        return "Parameter '$name' is not a boolean type";
    }

    return if $param eq "0";
    return if $param eq "1";

    return if ref $param eq 'SCALAR' and $$param eq "0" || $$param eq "1";

    return if $param eq TRUE;
    return if $param eq FALSE;

    ## this was added for Nathan, thinking PHP wasn't encoding booleans coorectly
#     return if lc $param eq "true";
#     return if lc $param eq "false";

    ## NOTE: if you use == here instead of eq, you get odd results, like "true" == 0
    return if defined $self->true  and $param eq $self->true;
    return if defined $self->false and $param eq $self->false;

    return "Parameter '$name' is not a valid boolean type";
}

sub debug {
    return unless $DEBUG;

    my $self = shift;
    my $msg  = shift;
    my @msg  = split /\r?\n/ => $msg;

    my $level = 0;
    while (defined((caller($level))[0])) { $level++ }

    my $sp = (">" x $level);

    if ($COLORED) {
        my @colors = qw/ white magenta cyan blue green /;
        $sp = colored($sp, $colors[$level % scalar @colors]);
    }

    $sp .= "    ";
    say STDERR $sp . $_ for @msg;

}

1;
__END__

=encoding utf8

=head1 NAME

JSON::Schema::Naive - A naïve implementation of JSON-Schema

=head1 SYNOPSIS

  use JSON::Schema::Naive;

  my $s = JSON::Schema::Naive->new($schema);

  $s->validate($object)
    or die join("\n\t", "The following errors occurred:", $s->errors);

=head1 DESCRIPTION

B<JSON::Schema::Naive> implements a simplistic subset of JSON-Schema
v4-draft. In this document, the phrases "schema" and "JSON object" are
really a native Perl representations of JSON objects, such as you'd
get from B<decode_json()>. This module does absolutely no JSON
serialization of any kind--use your favorite JSON module for that.

=head2 Attributes

=over 4

=item B<errors>

The current list of errors (read-only); reset using B<reset()> (see L</Methods>).

=item B<schema([$schema])>

The current schema this object will be validating. Sets ths schema if supplied.

=back

=head2 Methods

=over 4

=item B<new(%args)>

Creates a new B<JSON::Schema::Naive> object. Valid arguments:

=over 8

=item true

A subroutine reference to your JSON serializer's B<true()> method:

    $j = JSON::Schema::Naive->new(true => sub { Mojo::JSON->true });

=item false

A subroutine reference to your JSON serializer's B<false()> method.

=item schema

The schema this object will be validating against. May also be set via
the B<schema> attribute below.

=back

The following three statement sets are equivalent:

    $j = JSON::Schema::Naive->new;
    $j->schema($schema);
    $j->validate($obj);

is the same as this:

    $j = JSON::Schema::Naive->new(schema => $schema);
    $j->validate($obj);

and this:

    $j = JSON::Schema::Naive->new;
    $j->validate($schema => $obj);

=item B<validate([$schema], $obj)>

Validates a JSON object against a schema. If an optional I<$schema>
argument is supplied, it will be set as the object's default schema,
as if you had done this:

    $j->schema($schema);
    $j->validate($obj);

which is the same as:

    $j->validate($schema, $obj);

=item B<reset>

Resets all errors on an object. B<reset()> is called internally
whenever you invoke B<validate()>, so you'll need to save the errors
between calls to B<validate()> if you need to collect them.

    $j->reset;

=item B<true>

=item B<false>

Sets or invokes the true/false callbacks.

=back

=head1 SEE ALSO

L<JSON::Schema>, L<JSON>, L<JSON::XS>, L<Mojo::JSON>

=head1 AUTHOR

Scott Wiersdorf, E<lt>scott@betterservers.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Scott Wiersdorf

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
