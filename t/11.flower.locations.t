#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper::Concise; # For Dumper().

use FindBin;

use Mojolicious::Validator;

use Test::More;

use Text::CSV::Encoded;

use WWW::Garden::Design::Util::Filer;

# ------------------------------------------------

sub test_flower_locations
{
	my($filer, $validator, $validation, $test_count) = @_;

	# 1: Read flowers.csv in order to later validate the common_name column of flower_locations.csv.

	my(%flowers);

	my($path)					= "$FindBin::Bin/../data/flowers.csv";
	my($flowers)				= $filer -> read_csv_file($path);
	$flowers{$$_{common_name} }	= 1 for @$flowers;

	# 2: Read flower_locations.csv.

	my($table_name)			= 'flower_locations';
	$path					=~ s/flowers/$table_name/;
	my($flower_locations)	= $filer -> read_csv_file($path);

	# 2: Read properties.csv.

	my($table_name)	= 'properties';
	$path			=~ s/flowers/$table_name/;
	my($properties)	= $filer -> read_csv_file($path);

	# 2: Read gardens.csv.

	my($table_name)	= 'gardens';
	$path			=~ s/flowers/$table_name/;
	my($gardens)	= $filer -> read_csv_file($path);

	# 3: Validate the headings in flower_locations.csv.

	my(@expected_headings)	= sort(qw/common_name property_name garden_name xy/);
	my(@got_headings)		= sort keys %{$$flower_locations[0]};

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

	# 4: Validate the data in flower_locations.csv.

	my($common_name);

	for my $line (@$flower_locations)
	{
		# Check common names.

		$common_name = $$line{common_name};

		ok($flowers{$common_name}, "Common name '$common_name'. Name present in flowers.csv"); $test_count++;

		for my $column (@expected_headings)
		{
			ok(length($$line{$column}) > 0, "Common name: '$common_name', value: '$$line{$column}' ok"); $test_count++;
		}

	}

	return $test_count;

} # End of test_flower_locations.

# ------------------------------------------------

my($filer)		= WWW::Garden::Design::Util::Filer -> new;
my($test_count)	= 0;
my($validator)	= Mojolicious::Validator -> new;
my($validation)	= $validator -> validation;
$test_count		= test_flower_locations($filer, $validator, $validation, $test_count);

print "# Internal test count: $test_count\n";

done_testing($test_count);
