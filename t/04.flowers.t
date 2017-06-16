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
	my($filer, $validator, $validation, $test_count) = @_;
	my($path)		= "$FindBin::Bin/../data/flowers.csv";
	my($flowers)	= $filer -> read_csv_file($path);

	# 1: Validate the headings in properties.csv.
	# The headings must be listed here in the same order as in the file.

	my(@expected_headings)	= sort ('common_name', 'scientific_name', 'aliases', 'height', 'width', 'publish');
	my(@got_headings)		= sort keys %{$$flowers[0]};

	my($result);

	for my $i (0 .. $#expected_headings)
	{
		$result = $validation
		-> input({expected => $expected_headings[$i], got => $got_headings[$i]})
		-> required('got')
		-> equal_to('expected')
		-> is_valid;

		ok($result == 1, "Heading '$expected_headings[$i]' ok"); $test_count++;
	}

	# 2: Validate the data in flowers.csv.

	my($checker) = WWW::Garden::Design::Util::Validator -> new;

	$checker -> add_attribute_range_check;

	my($common_name, %common_names);

	for my $params (@{$filer -> read_csv_file($path)})
	{
		# Test common name.

		$common_name	= $$params{common_name};
		$result			= $checker -> required_check($params, 'common_name');

		ok($result == 1, "Common name '$common_name' ok"); $test_count++;

		$common_names{$common_name} = 0 if (! $common_names{$common_name});

		$common_names{$common_name}++;

		# Test scientific name.

		$result = $checker -> required_check($params, 'scientific_name');

		ok($result == 1, "Common name '$common_name'. Scientific name '$$params{scientific_name} ok"); $test_count++;

		# Test publish flag.
		#
		# Comment out complex test.
		#$result = $validation
		#-> required('publish')
		#-> in('Yes', 'No')
		#-> is_valid;
		#
		#ok($result == 1, "Common name '$common_name'. Publish '$$params{publish} is Yes or No"); $test_count++;

		ok($$params{publish} =~ /^Yes|No$/, "Common name '$common_name'. Publish is Yes or No"); $test_count++;

		# Test height.

		$result = $checker -> range_check($params, 'height');

		ok($result == 1, "Common name '$common_name'. Height '$$params{height}' is ok"); $test_count++;

		# Test width.

		$result = $checker -> range_check($params, 'width');

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
my($validator)	= Mojolicious::Validator -> new;
my($validation)	= $validator -> validation;
$test_count		= test_flowers($filer, $validator, $validation, $test_count);

print "# Internal test count: $test_count\n";

done_testing($test_count);
