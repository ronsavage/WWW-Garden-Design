#!/usr/bin/env perl

use strict;
use warnings;
use open qw(:std :utf8); # Undeclared streams in UTF-8.

use Data::Dumper::Concise; # For Dumper().

use FindBin;

use Mojolicious::Validator;

use Test::More;

use Text::CSV::Encoded;

use WWW::Garden::Design::Util::Filer;

# ------------------------------------------------

sub test_objects
{
	my($filer, $validator, $validation, $test_count) = @_;
	my($path)		= "$FindBin::Bin/../data/flowers.csv";
	my($table_name) = 'objects';
	$path			=~ s/flowers/$table_name/;
	my($objects)	= $filer -> read_csv_file($path);

	# 1: Validate the headings in objects.csv.

	my(@expected_headings)	= sort(qw/name hex_color publish/);
	my(@got_headings)		= sort keys %{$$objects[0]};

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

	# 2: Validate the data in objects.csv.

	my($name, %names);

	for my $line (@$objects)
	{
		$name = $$line{name};

		ok(length($name) > 0, "Value: '$name' ok"); $test_count++;
		ok($$line{hex_color} =~ /^#[0-9A-F]{6,6}$/i, "Value: $$line{hex_color} ok"); $test_count++;
		ok($$line{publish} =~ /^Yes|No$/, "Object name '$name'. Publish is Yes or No"); $test_count++;

		$names{$name} = 0 if (! $names{$name});

		$names{$name}++;
	}

	for $name (sort keys %names)
	{
		ok($names{$name} == 1, "Object '$name' is unique"); $test_count++;
	}

	return $test_count;

} # End of test_objects.

# ------------------------------------------------

my($filer)		= WWW::Garden::Design::Util::Filer -> new;
my($test_count)	= 0;
my($validator)	= Mojolicious::Validator -> new;
my($validation)	= $validator -> validation;
$test_count		= test_objects($filer, $validator, $validation, $test_count);

print "# Internal test count: $test_count\n";

done_testing($test_count);
