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

sub test_notes
{
	my($filer, $validator, $validation, $test_count, $property_names) = @_;

	# 1: Read flowers.csv in order to later validate the common_name column of notes.csv.

	my(%flowers);

	my($path)					= "$FindBin::Bin/../data/flowers.csv";
	my($flowers)				= $filer -> read_csv_file($path);
	$flowers{$$_{common_name} }	= 1 for @$flowers;

	# 2: Read notes.csv.

	my($table_name) = 'notes';
	$path           =~ s/flowers/$table_name/;
	my($notes)		= $filer -> read_csv_file($path);

	# 3: Validate the headings in notes.csv.

	my(@expected_headings)	= sort(qw/common_name sequence note/);
	my(@got_headings)		= sort keys %{$$notes[0]};

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

	# 4: Validate the data in notes.csv.

	my($common_name);
	my($sequence, %sequences);

	for my $line (@$notes)
	{
		# Check common names.

		$common_name = $$line{common_name};

		ok($flowers{$common_name}, "Common name '$common_name'. Name present in notes.csv"); $test_count++;

		for my $column (qw/common_name sequence note/)
		{
			ok(length($$line{$column}) > 0, "Common name: '$common_name', value: '$$line{$column}' ok"); $test_count++;
		}

		# Don't check notes. They may be duplicated!

		# Check sequences.

		$sequence					= $$line{sequence};
		$sequences{$common_name}	= {} if (! $sequences{$common_name});

		ok($sequence =~ /^[0-9]{1,3}$/, "Image sequence '$sequence' ok"); $test_count++;

		$sequences{$common_name}{$sequence}++;
	}

	for $common_name (sort keys %sequences)
	{
		for $sequence (sort keys %{$sequences{$common_name} })
		{
			ok($sequences{$common_name}{$sequence} == 1, "Sequence '$sequence' is unique within common name '$common_name'"); $test_count++;
		}
	}

	return $test_count;

} # End of test_notes.

# ------------------------------------------------

my($filer)		= WWW::Garden::Design::Util::Filer -> new;
my($test_count)	= 0;
my($validator)	= Mojolicious::Validator -> new;
my($validation)	= $validator -> validation;
$test_count		= test_notes($filer, $validator, $validation, $test_count);

print "# Internal test count: $test_count\n";

done_testing($test_count);
