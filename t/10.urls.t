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

sub test_urls
{
	my($filer, $checker, $test_count) = @_;

	# 1: Read flowers.csv in order to later validate the common_name column of urls.csv.

	my(%flowers);

	my($path)					= "$FindBin::Bin/../data/flowers.csv";
	my($flowers)				= $filer -> read_csv_file($path);
	$flowers{$$_{common_name} }	= 1 for @$flowers;

	# 2: Read urls.csv.

	my($table_name) = 'urls';
	$path			=~ s/flowers/$table_name/;
	my($urls)		= $filer -> read_csv_file($path);

	# 3: Validate the headings in urls.csv.

	my(@expected_headings)	= sort(qw/common_name url/);
	my(@got_headings)		= sort keys %{$$urls[0]};

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

	# 4: Validate the data in images.csv.

	my($common_name);

	for my $params (@$urls)
	{
		# Check common names.

		$common_name = $$params{common_name};

		ok($checker -> check_key_exists(\%flowers, $common_name) == 1, "Common name '$common_name'. Name present in flowers.csv"); $test_count++;

		for my $column (@expected_headings)
		{
			ok($checker -> check_key_exists($params, $column) == 1, "Common name '$common_name', value '$$params{$column}' ok"); $test_count++;
		}

		# Check URL.
		# Skip.
	}

	return $test_count;

} # End of test_urls.

# ------------------------------------------------

my($checker)	= MojoX::Validate::Util -> new;
my($filer)		= WWW::Garden::Design::Util::Filer -> new;
my($test_count)	= 0;
$test_count		= test_urls($filer, $checker, $test_count);

print "# Internal test count: $test_count\n";

done_testing($test_count);
