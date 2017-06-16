#!/usr/bin/env perl

use strict;
use warnings;
use open qw(:std :utf8); # Undeclared streams in UTF-8.

use Data::Dumper::Concise; # For Dumper().

use FindBin;

use Mojolicious::Validator;

use Params::Classify 'is_number';

use Test::More;

use WWW::Garden::Design::Util::Filer;
use WWW::Garden::Design::Util::Validator;

# ------------------------------------------------

sub test_flowers
{
	my($filer, $test_count)	= @_;
	my($checker)			= WWW::Garden::Design::Util::Validator -> new;
	my($path)				= "$FindBin::Bin/../data/flowers.csv";
	my($flowers)			= $filer -> read_csv_file($path);

	# 1: Validate the headings in properties.csv.
	# The headings must be listed here in the same order as in the file.

	my(@expected_headings)	= sort ('common_name', 'scientific_name', 'aliases', 'height', 'width', 'publish');
	my(@got_headings)		= sort keys %{$$flowers[0]};

	my($result);

	for my $i (0 .. $#expected_headings)
	{
		$result = $checker -> check_equal_to
					(
						{expected => $expected_headings[$i], got => $got_headings[$i]},
						'got',
						'expected'
					);

		ok($result == 1, "Heading '$expected_headings[$i]' ok"); $test_count++;
	}

	# 2: Validate the data in flowers.csv.

	$checker -> add_attribute_range_check;

	my($common_name, %common_names);

	for my $params (@{$filer -> read_csv_file($path)})
	{
		# Test common name, and stash for duplicate testing later.

		$common_name	= $$params{common_name};
		$result			= $checker -> check_required($params, 'common_name');

		ok($result == 1, "Common name '$common_name' ok"); $test_count++;

		$common_names{$common_name} = 0 if (! $common_names{$common_name});

		$common_names{$common_name}++;

		# Test scientific name.

		$result = $checker -> check_required($params, 'scientific_name');

		ok($result == 1, "Common name '$common_name'. Scientific name '$$params{scientific_name} ok"); $test_count++;

		# Test publish flag.

		$result = $checker -> check_member($params, 'publish', 'Yes', 'No');

		ok($result  == 1, "Common name '$common_name'. Publish is Yes or No"); $test_count++;

		# Test height.

		$result = $checker -> check_attribute_range($params, 'height');

		ok($result == 1, "Common name '$common_name'. Height '$$params{height}' is ok"); $test_count++;

		# Test width.

		$result = $checker -> check_attribute_range($params, 'width');

		ok($result == 1, "Common name '$common_name'. Width '$$params{width}' is ok"); $test_count++;
	}

	for $common_name (sort keys %common_names)
	{
		ok($common_names{$common_name} == 1, "Common name '$common_name' not duplicated"); $test_count++;
	}

	return $test_count;

} # End of test_flowers.

# ------------------------------------------------

my($filer)		= WWW::Garden::Design::Util::Filer -> new;
my($test_count)	= 0;
$test_count		= test_flowers($filer, $test_count);

print "# Internal test count: $test_count\n";

done_testing($test_count);
