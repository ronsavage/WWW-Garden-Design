#!/usr/bin/env perl

use lib 'lib';
use strict;
use warnings;

use Test::More;

use WWW::Garden::Design::Util::Validator;

# ------------------------------------------------

my($test_count)	= 0;
my($checker)	= WWW::Garden::Design::Util::Validator -> new;

$checker -> add_dimension_check;

my(@data) =
(
	{height => ''},
	{height => '1'},
	{height => '1cm'},
	{height => '1 cm'},
	{height => '1m'},
	{height	=> '40-70.5cm'},
	{height	=> '1.5-2m'},
	{height => 'z1'},
);

my($expected);
my($infix);
my($message);

for my $params (@data)
{
	$expected	= ($$params{height} =~ /^z/) ? 0 : 1;
	$infix		= $expected ? '' : 'not ';
	$message	= "Height '$$params{height}' is ${infix}a valid height";

	ok($checker -> check_dimension($params, 'height', ['cm', 'm']) == $expected, $message); $test_count++;
}

ok($checker -> check_optional({x => ''}, 'x') == 1, 'Length 0 is ok'); $test_count++;

print "# Internal test count: $test_count\n";

done_testing($test_count);
