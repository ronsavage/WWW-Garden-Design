#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper::Concise; # For Dumper().

use FindBin;

use Test::More;

use Text::CSV::Encoded;

use WWW::Garden::Design::Validation::AttributeTypes;

# -----------------------

my($path) = "$FindBin::Bin/../data/flowers.csv";
my($csv)  = Text::CSV::Encoded -> new
({
	allow_whitespace => 1,
	encoding_in      => 'utf-8',
});
my($table_name) = 'attribute_types';
$path           =~ s/flowers/$table_name/;

open(my $io, '<', $path) || die "Can't open($path): $!\n";

my($attribute_type_keys)	= {};
my($test_count)				= 0;
my($checker)				= WWW::Garden::Design::Validation::AttributeTypes -> new;
my(@expected)				= ('name','sequence','range');
my(@headings)				= @{$csv -> getline($io) };

my($result);

for my $i (0 .. $#expected)
{
	$result = $checker -> validation
	-> optional($headings[$i], 'trim')
	-> input({heading => $headings[$i]})
	-> required('heading')
	-> like(qr/^$expected[$i]$/);

	ok($checker -> validation -> is_valid == 1, "Heading '$expected[$i]' found"); $test_count++;
}

close $io;

print "# Internal test count: $test_count\n";

done_testing($test_count);
