#!/usr/bin/env perl

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.
use open      qw(:std :utf8); # Undeclared streams in UTF-8.

use FindBin;

use MojoX::Validate::Util;

use Test::More;

use Text::CSV::Encoded;

use WWW::Garden::Design::Util::Filer;

# ------------------------------------------------

sub test_attribute_types
{
	my($filer, $checker, $test_count, $expected_attribute_types) = @_;
	my($path)				= "$FindBin::Bin/../data/flowers.csv";
	my($table_name)			= 'attribute_types';
	$path					=~ s/flowers/$table_name/;
	my($attributes_types)	= $filer -> read_csv_file($path);

	# 1: Validate the headings in attribute_types.csv.
	# The headings must be listed here in the same order as in the file.

	my(@expected_headings)	= sort(qw/name range/);
	my(@got_headings)		= sort keys %{$$attributes_types[0]};

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

	# 2: Validate the data in attribute_types.csv.

	my($expected_keys) = [keys %$expected_attribute_types];

	my($expected_format, $expected_set);
	my($name);
	my(@range, $range);

	for my $params (@$attributes_types)
	{
		$name				= $$params{name};
		$expected_format	= $$expected_attribute_types{$name};
		$expected_set		= [split(/, /, $$expected_format[0])];
		@range				= split(/, /, $$params{range});

		ok($checker -> check_member($params, 'name', $expected_keys), "Attribute type '$name' ok"); $test_count++;

		for $range (@range)
		{
			$result = $checker -> check_member
						(
							{got => $range},
							'got',
							$expected_set
						);

			ok($result == 1, "Attribute type '$name'. Range '$range' ok"); $test_count++;
		}
	}

	return $test_count;

} # End of test_attribute_types.

# ------------------------------------------------

sub test_attributes
{
	my($filer, $checker, $test_count, $expected_attribute_types) = @_;

	# 1: Read flowers.csv in order to later validate the common_name column of attributes.csv.

	my(%flowers);

	my($path)						= "$FindBin::Bin/../data/flowers.csv";
	my($flowers)					= $filer -> read_csv_file($path);
	$flowers{$$_{scientific_name} }	= 1 for @$flowers;

	# 2: Read attributes.csv.

	my($table_name) = 'attributes';
	$path			=~ s/flowers/$table_name/;
	my($attributes)	= $filer -> read_csv_file($path);

	# 3: Validate the headings in attributes.csv.
	# The headings must be listed here in the same order as in the file.

	my(@expected_headings)	= sort ('scientific_name', 'attribute_name', 'range');
	my(@got_headings)		= sort keys %{$$attributes[0]};

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

	# 4: Validate the data in attributes.csv.
	# Prepare flowers.

	my($expected_keys) = [keys %$expected_attribute_types];

	my(%got_attributes);
	my($scientific_name, %scientific_name);

	for my $line (@$flowers)
	{
		$scientific_name					= $$line{scientific_name};
		$scientific_name{$scientific_name} 	= 1;
		$got_attributes{$scientific_name}	= {};
	}

	# Prepare ranges.

	my(%expected_attributes);

	for my $name (keys %$expected_attribute_types)
	{
		$expected_attributes{$name}					= {};
		$expected_attributes{$name}{$_} 			= 1 for (split(/,\s*/, ${$$expected_attribute_types{$name} }[0]));
		$got_attributes{$scientific_name}{$name}	= 0;
	}

	# Test attributes.csv.

	my($count) = 0;

	my($expected_format, $expected_set);
	my($name);
	my(@range, $range);

	for my $params (@$attributes)
	{
		$count++;

		$scientific_name	= $$params{scientific_name};
		$name				= $$params{attribute_name};
		$expected_format	= $$expected_attribute_types{$name};
		$expected_set		= [split(/, /, $$expected_format[0])];
		@range				= split(/, /, $$params{range});

		$got_attributes{$scientific_name}{$name}++;

		ok($checker -> check_member($params, 'attribute_name', $expected_keys), "Attribute '$name' ok"); $test_count++;
		ok($checker -> check_member($params, 'scientific_name', [keys %scientific_name]), "Attribute '$name', scientific_name '$scientific_name' ok"); $test_count++;

		for $range (@range)
		{
			$result = $checker -> check_member
						(
							{got => $range},
							'got',
							$expected_set
						);

			ok($result == 1, "Attribute type '$name'. Range '$range' ok"); $test_count++;
		}
	}

	# Test counts of attribute types.

	for $scientific_name (sort keys %got_attributes)
	{
		for $name (sort keys %{$got_attributes{$scientific_name} })
		{
			ok($checker -> check_number($got_attributes{$scientific_name}, $name, 1) == 1, "Scientific name '$scientific_name', attribute '$name' occurs once"); $test_count++;
		}
	}

	return $test_count;

} # End of test_attributes.

# ------------------------------------------------

my($expected_attribute_types) =
{
	'Edible'		=> ['No, Bean, Flower, Fruit, Leaf, Stem, Rhizome, Unknown'],
	'Habit'			=> ['Columnar, Dwarf, Semi-dwarf, Prostrate, Shrub, Tree, Vine, Unknown'],
	'Kind'			=> ['Herb, Plant, Tree, Vegetable'],
	'Native'		=> ['Yes, No, Unknown'],
	'Sun tolerance'	=> ['Full sun, Part shade, Shade, Unknown'],
};
my($checker)	= MojoX::Validate::Util -> new;
my($filer)		= WWW::Garden::Design::Util::Filer -> new;
my($test_count)	= 0;
$test_count		= test_attribute_types($filer, $checker, $test_count, $expected_attribute_types);
$test_count		= test_attributes($filer, $checker, $test_count, $expected_attribute_types);

print "# Internal test count: $test_count\n";

done_testing($test_count);
