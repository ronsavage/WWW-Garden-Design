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

# ------------------------------------------------

sub test_flowers
{
	my($filer, $validator, $validation, $test_count) = @_;
	my($path)	= "$FindBin::Bin/../data/flowers.csv";

	my(@range);

	$validator -> add_check
	(
		range => sub
		{
			my($validation, $name, $value, @args) = @_;

			return 1 if ($value !~ /^([^cm]+)(?:c?m){0,1}$/);

			@range = split(/-/, $1);

			return 1 if ($#range > 1);		# 1-2-3 is unaccepatable.

			# A number is acceptable, so return 0!.

			if ($#range == 0)
			{
				return ! is_number($range[0]);
			}
			else
			{
			 	return ! is_number($range[1]);
			}
		}
	);

	my($common_name, %common_names);
	my($result);

	for my $line (@{$filer -> read_csv_file($path)})
	{
		# Test common name.

		$common_name	= $$line{'common_name'};
		$result			= $validation
		-> input($line)
		-> required('common_name')
		-> is_valid || 0;

		ok($result == 1, "Common name '$common_name' ok"); $test_count++;

		$common_names{$common_name}	= 0 if (! $common_names{$common_name});

		$common_names{$common_name}++;

		# Test scientific name.

		$result = $validation
		-> required('scientific_name')
		-> is_valid || 0;

		ok($result == 1, "Common name '$common_name'. Scientific name '$$line{scientific_name} ok"); $test_count++;

		# Test publish flag.

		$result = $validation
		-> required('publish')
		-> in('Yes', 'No')
		-> is_valid || 0;

		ok($result == 1, "Common name '$common_name'. Publish '$$line{publish} is Yes or No"); $test_count++;

		# Test height.

		$result = (length($$line{height}) == 0)
		|| $validation
		-> input($line)
		-> required('height')
		-> range
		-> is_valid;

		ok($result == 1, "Common name '$common_name'. Height '$$line{height}' is ok"); $test_count++;

		# Test width.

		$result = (length($$line{width}) == 0)
		|| $validation
		-> input($line)
		-> required('width')
		-> range
		-> is_valid;

		ok($result == 1, "Common name '$common_name'. Width '$$line{width}' is ok"); $test_count++;
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