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

sub test_attribute_types
{
	my($filer, $validator, $validation, $test_count, $expected_attribute_types) = @_;
	my($path)				= "$FindBin::Bin/../data/flowers.csv";
	my($table_name)			= 'attribute_types';
	$path					=~ s/flowers/$table_name/;
	my($attributes_types)	= $filer -> read_csv_file($path);

	# 1: Validate the headings in attribute_types.csv.
	# The headings must be listed here in the same order as in the file.

	my(@expected_headings)	= sort('name', 'sequence', 'range');
	my(@got_headings)		= sort keys %{$$attributes_types[0]};

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

	# 2: Validate the data in attribute_types.csv.

	my($expected_format);
	my($name);
	my($range);
	my($sequence);

	for my $line (@$attributes_types)
	{
		$range				= $$line{range};
		$sequence			= $$line{sequence};
		$name				= $$line{name};
		$expected_format	= $$expected_attribute_types{$name};

		ok($expected_format, "Attribute type '$name'"); $test_count++;

		if (! $expected_format)
		{
			BAIL_OUT('No point continuing when the above test fails');
		}

		if ($$expected_format[0] eq 'Integer')
		{
			ok($sequence =~ /^[0-9]{1,3}$/, "Attribute type sequence '$sequence' ok"); $test_count++;
		}

		ok($range eq $$expected_format[1], "Attribute type range '$range' ok"); $test_count++;
	}

	return $test_count;

} # End of test_attribute_types.

# ------------------------------------------------

sub test_attributes
{
	my($filer, $validator, $validation, $test_count, $expected_attribute_types) = @_;

	# 1: Read flowers.csv in order to later validate the common_name column of attributes.csv.

	my(%flowers);

	my($path)					= "$FindBin::Bin/../data/flowers.csv";
	my($flowers)				= $filer -> read_csv_file($path);
	$flowers{$$_{common_name} }	= 1 for @$flowers;

	# 2: Read attributes.csv.

	my($table_name) = 'attributes';
	$path			=~ s/flowers/$table_name/;
	my($attributes)	= $filer -> read_csv_file($path);

	# 3: Validate the headings in attributes.csv.
	# The headings must be listed here in the same order as in the file.

	my(@expected_headings)	= sort ('common_name', 'attribute_name', 'range');
	my(@got_headings)		= sort keys %{$$attributes[0]};

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

	# 4: Validate the data in attributes.csv.
	# Prepare flowers.

	my($common_name, %common_names);
	my(%got_attributes);

	for my $line (@$flowers)
	{
		$common_name					= $$line{common_name};
		$common_names{$common_name} 	= 1;
		$got_attributes{$common_name}	= {};
	}

	# Prepare ranges.

	my(%expected_attributes);

	for my $name (keys %$expected_attribute_types)
	{
		$expected_attributes{$name}				= {};
		$expected_attributes{$name}{$_} 		= 1 for (split(/, /, ${$$expected_attribute_types{$name} }[1]));
		$got_attributes{$common_name}{$name}	= 0;
	}

	# Test attributes.csv.

	my($count) = 0;

	my($expected_format);
	my($name);
	my($range);

	for my $line (@$attributes)
	{
		$count++;

		$common_name		= $$line{common_name};
		$name				= $$line{attribute_name};
		$expected_format	= $$expected_attribute_types{$name};

		$got_attributes{$common_name}{$name}++;

		ok($expected_attributes{$name}, "Attribute '$name'"); $test_count++;
		ok($common_names{$common_name}, "Attribute '$name', common_name '$common_name' ok"); $test_count++;

		for $range (split(/, /, $$line{range}) )
		{
			ok($expected_attributes{$name}{$range}, "Attribute '$name', range '$range' ok"); $test_count++;
		}
	}

	# Test counts of attribute types.

	for $common_name (sort keys %got_attributes)
	{
		for $name (sort keys %{$got_attributes{$common_name} })
		{
			ok ($got_attributes{$common_name}{$name} == 1, "Common name '$common_name', attribute '$name' occurs once"); $test_count++;
		}
	}

	return $test_count;

} # End of test_attributes.

# ------------------------------------------------

my($expected_attribute_types) =
{
	'Edible'		=> ['Integer', 'No, Bean, Flower, Fruit, Leaf, Stem, Rhizome, Unknown'],
	'Habit'			=> ['Integer', 'Columnar, Dwarf, Semi-dwarf, Prostrate, Shrub, Tree, Vine, Unknown'],
	'Native'		=> ['Integer', 'Yes, No, Unknown'],
	'Sun tolerance'	=> ['Integer', 'Full sun, Part shade, Shade, Unknown'],
};
my($filer)		= WWW::Garden::Design::Util::Filer -> new;
my($test_count)	= 0;
my($validator)	= Mojolicious::Validator -> new;
my($validation)	= $validator -> validation;
$test_count		= test_attribute_types($filer, $validator, $validation, $test_count, $expected_attribute_types);
$test_count		= test_attributes($filer, $validator, $validation, $test_count, $expected_attribute_types);

print "# Internal test count: $test_count\n";

done_testing($test_count);
