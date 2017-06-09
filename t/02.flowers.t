#!/usr/bin/env perl

use strict;
use warnings;
use open qw(:std :utf8); # Undeclared streams in UTF-8.

use Data::Dumper::Concise; # For Dumper().

use FindBin;

use Mojolicious::Validator;

use Test::More;

use WWW::Garden::Design::Util::Filer;

# ------------------------------------------------

sub test_flowers
{
	my($filer, $validator, $validation, $test_count) = @_;
	my($path)	= "$FindBin::Bin/../data/flowers.csv";

	my($common_name, %common_names);
	my($result);

	for my $line (@{$filer -> read_csv_file($path)})
	{
		$common_name	= $$line{'common_name'};
		$result			= $validation
		-> input($line)
		-> required('common_name')
		-> is_valid || 0;

		ok($result == 1, "Common name '$common_name' ok"); $test_count++;

		$common_names{$common_name}	= 0 if (! $common_names{$common_name});

		$common_names{$common_name}++;

		$result = $validation
		-> required('scientific_name')
		-> is_valid || 0;

		ok($result == 1, "Scientific name '$$line{scientific_name} ok"); $test_count++;

		$result = $validation
		-> required('publish')
		-> in('Yes', 'No')
		-> is_valid || 0;

		ok($result == 1, "Publish '$$line{publish} is Yes or No"); $test_count++;
	}

	for $common_name (sort keys %common_names)
	{
		ok($common_names{$common_name} == 1, "Common name '$common_name' not duplicated"); $test_count++;
	}

=pod

	for my $line (@{$filer -> read_csv_file($path)})
	{
		$aliases			= $$line{'aliases'};
		$common_name		= $$line{'common_name'};
		$scientific_name	= $$line{'scientific_name'};
		$height				= $$line{'height'};
		$width				= $$line{'width'};
		$publish			= $$line{'publish'};

		ok($range eq $$expected_format[1], "Attribute type range '$range'"); $test_count++;
	}

=cut

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
