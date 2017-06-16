#!/usr/bin/env perl

use lib 'lib';
use strict;
use warnings;

use Test::More;

use WWW::Garden::Design::Util::Validator;

# ------------------------------------------------

my($test_count)	= 0;
my($checker)	= WWW::Garden::Design::Util::Validator -> new;

$checker -> add_attribute_range_check;

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
my($message);

for my $params (@data)
{
	$test_count++;

	$expected	= ($$params{height} =~ /z/) ? 0 : 1;
	$infix		= $expected ? 'a valid' : 'an invalid';
	$message	= "Height '$$params{height}' is $infix height";

	ok($checker -> check_attribute_range($params, 'height') == $expected, $message);
}

print "# Internal test count: $test_count\n";

done_testing($test_count);
