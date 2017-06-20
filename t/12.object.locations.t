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

sub test_object_locations
{
	my($filer, $validator, $validation, $test_count) = @_;

	# 1: Read objects.csv in order to later validate the name column of object_locations.csv.

	my(%objects);

	my($path)				= "$FindBin::Bin/../data/objects.csv";
	my($objects)			= $filer -> read_csv_file($path);
	$objects{$$_{name} }	= 1 for @$objects;

	# 2: Read object_locations.csv.

	my($table_name)			= 'object_locations';
	$path					=~ s/objects/$table_name/;
	my($object_locations)	= $filer -> read_csv_file($path);

	# 2: Read properties.csv.

	my(%properties);

	$table_name				= 'properties';
	$path					=~ s/object_locations/$table_name/;
	my($properties)			= $filer -> read_csv_file($path);
	$properties{$$_{name} }	= 1 for @$properties;

	# 2: Read gardens.csv.

	my(%gardens);

	$table_name					= 'gardens';
	$path						=~ s/properties/$table_name/;
	my($gardens)				= $filer -> read_csv_file($path);
	$gardens{$$_{garden_name} }	= 1 for @$gardens;

	# 3: Validate the headings in object_locations.csv.

	my(@expected_headings)	= sort(qw/name property_name garden_name xy/);
	my(@got_headings)		= sort keys %{$$object_locations[0]};

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

	# 4: Validate the data in object_locations.csv.

	my($garden_name);
	my($name);
	my($property_name);

	for my $line (@$object_locations)
	{
		# Check names.

		$name = $$line{name};

		ok($objects{$name}, "Name '$name'. Name present in objects.csv"); $test_count++;

		for my $column (@expected_headings)
		{
			ok(length($$line{$column}) > 0, "Name '$name', value '$$line{$column}' ok"); $test_count++;
		}

		# Check property names.

		$property_name = $$line{property_name};

		ok ($properties{$property_name}, "Property name '$property_name' ok"); $test_count++;

		# Check garden names.

		$garden_name = $$line{garden_name};

		ok ($gardens{$garden_name}, "Garden name '$garden_name' ok"); $test_count++;
	}

	return $test_count;

} # End of test_object_locations.

# ------------------------------------------------

my($filer)		= WWW::Garden::Design::Util::Filer -> new;
my($test_count)	= 0;
my($validator)	= Mojolicious::Validator -> new;
my($validation)	= $validator -> validation;
$test_count		= test_object_locations($filer, $validator, $validation, $test_count);

print "# Internal test count: $test_count\n";

done_testing($test_count);
