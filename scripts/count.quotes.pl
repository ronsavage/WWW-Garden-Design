#!/usr/bin/env perl

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.
use open      qw(:std :utf8); # Undeclared streams in UTF-8.

use File::Slurper 'read_lines';

use FindBin;

# -----------------------------------------------

sub check
{
	my($file_name)	= @_;
	my($file_path)	= "$FindBin::Bin/../data/$file_name.csv";
	my($line_count)	= 0;

	print "Processing $file_name. \n";

	my($expected_count);
	my($quote_count);

	for my $line (read_lines($file_path) )
	{
		$line_count++;

		$quote_count = $line =~ tr/"/"/;

		if ($line_count == 1)
		{
			$expected_count = $quote_count;
		}

		if ($expected_count != $quote_count)
		{
			print "$file_name. expected_count: $$expected_count. quote_count: $quote_count. \n";
		}
	}

}	# End of check.

# ------------------------------------------------

for my $file (qw/attribute_types attributes constants feature_locations
				features flower_locations flowers gardens images notes properties urls/)
{
	check($file);
}
