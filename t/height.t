#!/usr/bin/env perl

use strict;
use warnings;

use Mojolicious::Validator;

use Params::Classify 'is_number';

use Test::More;

# ------------------------------------------------

my($test_count)	= 0;
my($validator)	= Mojolicious::Validator -> new;
my($validation)	= $validator -> validation;

$validator -> add_check
(
	height => sub
	{
		my($validation, $name, $value, @args) = @_;

		return 1 if ($value !~ /^(.+)(?:cm|m){0,1}$/);

		return ! is_number($1); # A number is acceptable.
	}
);

my(@data) =
(
	{height => ''},
	{height => '1'},
	{height => '1cm'},
	{height => '1m'},
	{height => 'z1'},
);

my($result);

for my $line (@data)
{
	# This cannot use topic('height') instead of required() because of the work required() does.

	$result = (length($$line{height}) == 0)
	|| $validation
	-> input($line)
	-> required('height')
	-> height
	-> is_valid;

	ok($result == 1, "Height '$$line{height}' is ok"); $test_count++;
}

print "# Internal test count: $test_count\n";

done_testing($test_count);
