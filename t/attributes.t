#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper::Concise; # For Dumper().

use FindBin;

use Test::More;

use Text::CSV::Encoded;

use WWW::Garden::Design::Validation::AttributeTypes;

# ------------------------------------------------

sub test_attribute_types
{
	my($test_count, $expected_attribute_types) = @_;
	my($path)	= "$FindBin::Bin/../data/flowers.csv";
	my($csv)	= Text::CSV::Encoded -> new
	({
		allow_whitespace => 1,
		encoding_in      => 'utf-8',
	});
	my($table_name) = 'attribute_types';
	$path           =~ s/flowers/$table_name/;

	open(my $io, '<', $path) || die "Can't open($path): $!\n";

	# 1: Validate the headings in attribute_types.csv.

	my($checker)			= WWW::Garden::Design::Validation::AttributeTypes -> new;
	my(@expected_headings)	= ('name','sequence','range');
	my(@got_headings)		= @{$csv -> getline($io) };

	my($result);

	for my $i (0 .. $#expected_headings)
	{
		$result = $checker
		-> validation
		-> input({expected => $expected_headings[$i], got => $got_headings[$i]})
		-> required('got')
		-> equal_to('expected')
		-> is_valid || 0;

		ok($result == 1, "Heading '$expected_headings[$i]' found"); $test_count++;
	}

	# 2: Validate the data in attribute_types.csv.

	$csv -> column_names(@expected_headings);

	my($expected_format);
	my($range);
	my($sequence);
	my($type);

	for my $line (@{$csv -> getline_all($io)})
	{
		$range				= $$line[2];
		$sequence			= $$line[1];
		$type				= $$line[0];
		$expected_format	= $$expected_attribute_types{$type};

		ok($expected_format, "Attribute type '$type'"); $test_count++;

		if (! $expected_format)
		{
			BAIL_OUT('No point continuing when the above test fails');
		}

		if ($$expected_format[0] eq 'int')
		{
			ok($sequence =~ /^[0-9]{1,3}$/, "Attribute type sequence '$sequence'"); $test_count++;
		}

		ok($range eq $$expected_format[1], "Attribute type range '$range'"); $test_count++;
	}

	close $io;

	return $test_count;

} # End of test_attribute_types.

# ------------------------------------------------

sub test_attributes
{
	my($test_count, $expected_attribute_types) = @_;
	my($path)	= "$FindBin::Bin/../data/flowers.csv";
	my($csv)	= Text::CSV::Encoded -> new
	({
		allow_whitespace => 1,
		encoding_in      => 'utf-8',
	});
	my($table_name) = 'attributes';
	$path           =~ s/flowers/$table_name/;

	open(my $io, '<', $path) || die "Can't open($path): $!\n";

	# 1: Validate the headings in attributes.csv.

	my($checker)			= WWW::Garden::Design::Validation::AttributeTypes -> new;
	my(@expected_headings)	= ('common_name','attribute_name','range');
	my(@got_headings)		= @{$csv -> getline($io) };

	my($result);

	for my $i (0 .. $#expected_headings)
	{
		$result = $checker
		-> validation
		-> input({expected => $expected_headings[$i], got => $got_headings[$i]})
		-> required('got')
		-> equal_to('expected')
		-> is_valid || 0;

		ok($result == 1, "Heading '$expected_headings[$i]' found"); $test_count++;
	}

	# 2: Validate the data in attributes.csv.

	$csv -> column_names(@expected_headings);

	# Prepare ranges.

	my(%expected_attributes);

	for my $type (keys %$expected_attribute_types)
	{
		$expected_attributes{$type}		= {};
		$expected_attributes{$type}{$_} = 1 for (split(/, /, ${$$expected_attribute_types{$type} }[1]));
	}

	diag Dumper(%expected_attributes);

	my($count) = 0;

	my($common_name);
	my($expected_format);
	my($range);
	my($type);

	for my $line (@{$csv -> getline_all($io)})
	{
		$count++;

		$common_name		= $$line[0];
		$type				= $$line[1];
		$expected_format	= $$expected_attribute_types{$type};

		ok($expected_attributes{$type}, "Attribute '$type'"); $test_count++;

#		if (! $expected_format)
#		{
#			BAIL_OUT('No point continuing when the above test fails');
#		}

		for $range (split(/, /, $$line[2]) )
		{
			ok($expected_attributes{$type}{$range}, "Attribute '$type', range '$range'"); $test_count++;
		}
	}

	return $test_count;

} # End of test_attributes.

# ------------------------------------------------

my($expected_attribute_types) =
{
	'Edible'		=> ['int', 'No, Bean, Flower, Fruit, Leaf, Stem, Rhizome, Unknown'],
	'Habit'			=> ['int', 'Columnar, Dwarf, Semi-dwarf, Prostrate, Shrub, Tree, Vine, Unknown'],
	'Native'		=> ['int', 'Yes, No, Unknown'],
	'Sun tolerance'	=> ['int', 'Full sun, Part shade, Shade, Unknown'],
};
my($test_count)	= 0;
$test_count		= test_attribute_types($test_count, $expected_attribute_types);
$test_count		= test_attributes($test_count, $expected_attribute_types);

print "# Internal test count: $test_count\n";

done_testing($test_count);
