#!/usr/bin/env perl

use strict;
use warnings;

use WWW::Garden::Design::Util::Validator;

# ------------------------------------------------
# This is a copy of t/01.range.t, without the Test::More parts.

my(%count)		= (pass => 0, total => 0);
my($checker)	= WWW::Garden::Design::Util::Validator -> new;

$checker -> add_dimension_check;

my(@data) =
(
	{height => ''},				# Pass.
	{height => '1'},			# Fail. No unit.
	{height => '1cm'},			# Pass.
	{height => '1 cm'},			# Pass.
	{height => '1m'},			# Pass.
	{height	=> '40-70.5cm'},	# Pass.
	{height	=> '1.5-2m'},		# Pass.
	{height => 'z1'},			# Fail.
);

my($expected);
my($infix);

for my $params (@data)
{
	$count{total}++;

	$count{pass}++ if ($checker -> check_dimension($params, 'height', ['cm', 'm']) == 1);
}

$count{total}++;

$count{pass}++ if ($checker -> check_optional({x => ''}, 'x') == 1);

print "Test counts: \n", join("\n", map{"$_: $count{$_}"} sort keys %count), "\n";
