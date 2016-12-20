#!/usr/bin/env perl

use feature 'say';
use strict;
use warnings;

use File::Slurper qw/read_dir/;

use FindBin;

use Text::CSV::Encoded;

# -----------------------------------------------

sub fix
{
	my($csv)	= @_;
	my(%data)	=
	(
		'flowers'	=> read_csv_file($csv, 'flowers'),
		'images'	=> read_csv_file($csv, 'images'),
	);

	my($count)	= 0;
	my(%seen)	= (common_name => {}, scientific_name => {});

	my(%name);

	for my $flower (@{$data{flowers} })
	{
		$count++;

		$name{common_name}		= $$flower{common_name};
		$name{scientific_name}	= $$flower{scientific_name};

		for my $key (sort keys %seen)
		{
			if ($seen{$key}{$name{$key} })
			{
				print "Row: $count. Duplicate $key. $name{scientific_name}. $name{common_name}. \n";
			}

			$seen{$key}{$name{$key} } = 1;
		}
	}

}	# End of fix.

# ------------------------------------------------

sub read_csv_file
{
	my($csv, $table_name)	= @_;
	my($file_name)			= "data/$table_name.csv";

	open(my $io, '<', $file_name) || die "Can't open($file_name): $!\n";

	$csv -> column_names($csv -> getline($io) );

	return $csv -> getline_hr_all($io);

} # End of read_csv_file.

# ------------------------------------------------

my($csv) = Text::CSV::Encoded -> new
({
	always_quote	=> 1,
	encoding_in		=> 'utf-8',
});

fix($csv);
