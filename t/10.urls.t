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

sub test_urls
{
	my($filer, $validator, $validation, $test_count) = @_;

	# 1: Read flowers.csv in order to later validate the common_name column of urls.csv.

	my(%flowers);

	my($path)					= "$FindBin::Bin/../data/flowers.csv";
	my($flowers)				= $filer -> read_csv_file($path);
	$flowers{$$_{common_name} }	= 1 for @$flowers;

	# 2: Read urls.csv.

	my($table_name) = 'urls';
	$path           =~ s/flowers/$table_name/;
	my($urls)		= $filer -> read_csv_file($path);

	# 3: Validate the headings in urls.csv.

	my(@expected_headings)	= sort(qw/common_name sequence url/);
	my(@got_headings)		= sort keys %{$$urls[0]};

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

	# 4: Validate the data in images.csv.

	my($common_name);
	my($sequence, %sequences);

	for my $line (@$urls)
	{
		# Check common names.

		$common_name = $$line{common_name};

		ok($flowers{$common_name}, "Common name '$common_name'. Name present in flowers.csv"); $test_count++;

		for my $column (@expected_headings)
		{
			ok(length($$line{$column}) > 0, "Common name: '$common_name', value: '$$line{$column}' ok"); $test_count++;
		}

		# Check URL.
		# Skip.

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

} # End of test_urls.

# ------------------------------------------------

my($filer)		= WWW::Garden::Design::Util::Filer -> new;
my($test_count)	= 0;
my($validator)	= Mojolicious::Validator -> new;
my($validation)	= $validator -> validation;
$test_count		= test_urls($filer, $validator, $validation, $test_count);

print "# Internal test count: $test_count\n";

done_testing($test_count);
