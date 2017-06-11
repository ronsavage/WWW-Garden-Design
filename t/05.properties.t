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

sub test_properties
{
	my($filer, $validator, $validation, $test_count) = @_;
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
		-> is_valid || 0;

		ok($result == 1, "Heading '$expected_headings[$i]' ok"); $test_count++;
	}

	# 2: Validate the data in properties.csv.

	for my $line (@{$filer -> read_csv_file($path)})
	{
		for my $column (qw/description name publish/)
		{
			ok(length($$line{$column}) > 0, "Properties column: '$column', value: '$$line{$column}' ok"); $test_count++;
		}
	}

	return $test_count;

} # End of test_properties.

# ------------------------------------------------

my($filer)		= WWW::Garden::Design::Util::Filer -> new;
my($test_count)	= 0;
my($validator)	= Mojolicious::Validator -> new;
my($validation)	= $validator -> validation;
$test_count		= test_properties($filer, $validator, $validation, $test_count);

print "# Internal test count: $test_count\n";

done_testing($test_count);
