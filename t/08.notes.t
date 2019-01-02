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

sub test_notes
{
	my($filer, $checker, $test_count) = @_;

	# 1: Read flowers.csv in order to later validate the common_name column of notes.csv.

	my(%flowers);

	my($path)						= "$FindBin::Bin/../data/flowers.csv";
	my($flowers)					= $filer -> read_csv_file($path);
	$flowers{$$_{scientific_name} }	= 1 for @$flowers;

	# 2: Read notes.csv.

	my($table_name) = 'notes';
	$path			=~ s/flowers/$table_name/;
	my($notes)		= $filer -> read_csv_file($path);

	# 3: Validate the headings in notes.csv.

	my(@expected_headings)	= sort(qw/scientific_name note/);
	my(@got_headings)		= sort keys %{$$notes[0]};

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

	# 4: Validate the data in notes.csv.

	my($scientific_name);

	for my $params (@$notes)
	{
		# Check scientific names.

		$scientific_name = $$params{scientific_name};

		ok($checker -> check_key_exists(\%flowers, $scientific_name) == 1, "Scientific name '$scientific_name'. Name present in flowers.csv"); $test_count++;

		for my $column (@expected_headings)
		{
			ok($checker -> check_key_exists($params, $column) == 1, "Scientific name '$scientific_name', value '$$params{$column}' ok"); $test_count++;
		}

		# Don't check notes. They may be duplicated!
	}

	return $test_count;

} # End of test_notes.

# ------------------------------------------------

my($checker)	= MojoX::Validate::Util -> new;
my($filer)		= WWW::Garden::Design::Util::Filer -> new;
my($test_count)	= 0;
$test_count		= test_notes($filer, $checker, $test_count);

print "# Internal test count: $test_count\n";

done_testing($test_count);
