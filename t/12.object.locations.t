#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper::Concise; # For Dumper().

use FindBin;

use Mojolicious::Validator;

use Test::More;

use Text::CSV::Encoded;

use WWW::Garden::Design::Util::Filer;
use WWW::Garden::Design::Util::Validator;

# ------------------------------------------------

sub test_object_locations
{
	my($filer, $checker, $test_count) = @_;

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
		$result = $checker -> check_equal_to
					(
						{expected => $expected_headings[$i], got => $got_headings[$i]},
						'got',
						'expected'
					);

		ok($result == 1, "Heading '$expected_headings[$i]' ok"); $test_count++;
	}

	# 4: Validate the data in object_locations.csv.

	my($garden_name);
	my($name);
	my($property_name);
	my($xy, @xy, %xy);

	for my $params (@$object_locations)
	{
		# Check names.

		$name			= $$params{name};
		$garden_name	= $$params{garden_name};
		$property_name	= $$params{property_name};

		ok($checker -> check_key_exists(\%objects, $name) == 1, "Object name '$name'. Name present in objects.csv"); $test_count++;

		for my $column (@expected_headings)
		{
			ok($checker -> check_key_exists($params, $column) == 1, "Object name '$name', value '$$params{$column}' ok"); $test_count++;
		}

		for $xy (split(/\s+/, $$params{xy}) )
		{
			@xy										= split(/,\s*/, $xy);
			$xy{$property_name}						= {}	if (! $xy{$property_name});
			$xy{$property_name}{$garden_name}		= {}	if (! $xy{$property_name}{$garden_name});
			$xy{$property_name}{$garden_name}{$xy}	= 0		if (! $xy{$property_name}{$garden_name}{$xy});

			$xy{$property_name}{$garden_name}{$xy}++;

			ok($checker -> check_natural_number({x => $xy[0]}, 'x') == 1, "Object name '$name', xy '$xy'. X ok"); $test_count++;
			ok($checker -> check_natural_number({y => $xy[1]}, 'y') == 1, "Object name '$name', xy '$xy'. Y ok"); $test_count++;
		}

		ok ($checker -> check_key_exists(\%properties, $property_name) == 1, "Property name '$property_name' ok"); $test_count++;
		ok ($checker -> check_key_exists(\%gardens, $garden_name) == 1, "Garden name '$garden_name' ok"); $test_count++;
	}

	for $property_name (sort keys %xy)
	{
		for $garden_name (sort keys %{$xy{$property_name} })
		{
			for $xy (sort keys %{$xy{$property_name}{$garden_name} })
			{
				ok($checker -> check_count($xy{$property_name}{$garden_name}, $xy, 1) == 1, "Property name '$property_name'. Garden name '$garden_name'. XY '$xy' duplicated"); $test_count++;
			}
		}
	}

	return $test_count;

} # End of test_object_locations.

# ------------------------------------------------

my($checker)	= WWW::Garden::Design::Util::Validator -> new;
my($filer)		= WWW::Garden::Design::Util::Filer -> new;
my($test_count)	= 0;
$test_count		= test_object_locations($filer, $checker, $test_count);

print "# Internal test count: $test_count\n";

done_testing($test_count);
