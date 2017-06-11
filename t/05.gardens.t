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

sub test_gardens
{
	my($filer, $validator, $validation, $test_count, $property_names) = @_;
	my($path)	= "$FindBin::Bin/../data/flowers.csv";
	my($csv)	= Text::CSV::Encoded -> new
	({
		allow_whitespace => 1,
		encoding_in      => 'utf-8',
	});
	my($table_name) = 'gardens';
	$path           =~ s/flowers/$table_name/;

	# 1: Validate the headings in gardens.csv.
	# The headings must be listed here in the same order as in the file.

	open(my $io, '<', $path) || die "Can't open($path): $!\n";

	my(@expected_headings)	= ('property_name', 'garden_name', 'description', 'publish');
	my(@got_headings)		= @{$csv -> getline($io) };

	close $io;

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

	# 2: Validate the data in gardens.csv.

	my($garden_name, %garden_names);
	my($property_name);

	for my $line (@{$filer -> read_csv_file($path)})
	{
		for my $column (qw/description garden_name property_name publish/)
		{
			ok(length($$line{$column}) > 0, "Properties column: '$column', value: '$$line{$column}' ok"); $test_count++;

			if ($column eq 'property_name')
			{
				$garden_name	= $$line{garden_name};
				$property_name	= $$line{property_name};

				ok(exists $$property_names{$property_name}, "Property name '$property_name' present in properties.csv ok"); $test_count++;

				$garden_names{$property_name}				= {} if (! $garden_names{$property_name});
				$garden_names{$property_name}{$garden_name}	= 0 if (! $garden_names{$property_name}{$garden_name});

				$garden_names{$property_name}{$garden_name}++;
			}
			elsif ($column eq 'publish')
			{
				ok($$line{$column} =~ /^Yes|No$/, "Garden name '$$line{garden_name}'. Publish is Yes or No"); $test_count++;
			}
		}
	}

	for $property_name (sort keys %garden_names)
	{
		for $garden_name (sort keys %{$garden_names{$property_name} })
		{
			ok($garden_names{$property_name}{$garden_name} == 1, "Garden name '$garden_name' is unique within property '$property_name'"); $test_count++;
		}
	}

	return $test_count;

} # End of test_gardens.

# ------------------------------------------------

sub test_properties
{
	my($filer, $validator, $validation, $test_count, $property_names) = @_;
	my($path)	= "$FindBin::Bin/../data/flowers.csv";
	my($csv)	= Text::CSV::Encoded -> new
	({
		allow_whitespace => 1,
		encoding_in      => 'utf-8',
	});
	my($table_name) = 'properties';
	$path           =~ s/flowers/$table_name/;

	open(my $io, '<', $path) || die "Can't open($path): $!\n";

	# 1: Validate the headings in properties.csv.
	# The headings must be listed here in the same order as in the file.

	my(@expected_headings)	= ('name','description','publish');
	my(@got_headings)		= @{$csv -> getline($io) };

	close $io;

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

	# 2: Validate the data in properties.csv.

	my($property_name);

	for my $line (@{$filer -> read_csv_file($path)})
	{
		for my $column (qw/description name publish/)
		{
			ok(length($$line{$column}) > 0, "Properties column: '$column', value: '$$line{$column}' ok"); $test_count++;

			if ($column eq 'publish')
			{
				ok($$line{publish} =~ /^Yes|No$/, "Property name '$$line{name}'. Publish is Yes or No"); $test_count++;
			}
		}

		$property_name						= $$line{name};
		$$property_names{$property_name}	= 0 if (! $$property_names{$property_name});

		$$property_names{$property_name}++;
	}

	for $property_name (sort keys %$property_names)
	{
		ok($$property_names{$property_name} == 1, "Property name '$property_name' not duplicated"); $test_count++;
	}

	return $test_count;

} # End of test_properties.

# ------------------------------------------------

my($filer)		= WWW::Garden::Design::Util::Filer -> new;
my($test_count)	= 0;
my($validator)	= Mojolicious::Validator -> new;
my($validation)	= $validator -> validation;

my(%property_names);

$test_count	= test_properties($filer, $validator, $validation, $test_count, \%property_names);
$test_count	= test_gardens($filer, $validator, $validation, $test_count, \%property_names);

print "# Internal test count: $test_count\n";

done_testing($test_count);
