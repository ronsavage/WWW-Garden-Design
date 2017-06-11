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

my(@height);

$validator -> add_check
(
	height => sub
	{
		my($validation, $name, $value, @args) = @_;

		return 1 if ($value !~ /^([^cm]+)(?:c?m){0,1}$/);

		@height = split(/-/, $1);

		return 1 if ($#height > 1);		# 1-2-3 is unaccepatable.

		# A number is acceptable, so return 0!.

		if ($#height == 0)
		{
			return ! is_number($height[0]);
		}
		else
		{
		 	return ! is_number($height[1]);
		}
	}
);

my(@data) =
(
	{height => ''},
	{height => '1'},
	{height => '1cm'},
	{height => '1m'},
	{height	=> '40-70cm'},
	{height	=> '1.5-2m'},
	{height => 'z1'},
);

my($expected);
my($result);
my($suffix);

for my $line (@data)
{
	$expected	= ($$line{height} =~ /z/) ? 0 : 1;
	$suffix		= ($expected == 0) ? ' using a reversed test' : '';
	$result		= (length($$line{height}) == 0)
	|| $validation
	-> input($line)
	-> required('height')
	-> height
	-> is_valid;

	ok($result == $expected, "Height '$$line{height}' is a valid height$suffix"); $test_count++;
}

print "# Internal test count: $test_count\n";

done_testing($test_count);
