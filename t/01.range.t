#!/usr/bin/env perl

use lib 'lib';
use strict;
use warnings;

use Test::More;

use WWW::Garden::Design::Util::Validator;

# ------------------------------------------------

my($test_count)	= 0;
my($validator)	= WWW::Garden::Design::Util::Validator -> new;

$validator -> add_attribute_range_check;

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
my($infix);
my($result);

for my $line (@data)
{
	$expected	= ($$line{height} =~ /z/) ? 0 : 1;
	$infix		= $expected ? 'a valid' : 'an invalid';
	$result		= (length($$line{height}) == 0)
					|| $validator
					-> validation
					-> input($line)
					-> required('height')
					-> range
					-> is_valid;

	ok($result == $expected, "Height '$$line{height}' is $infix height"); $test_count++;
}

print "# Internal test count: $test_count\n";

done_testing($test_count);
