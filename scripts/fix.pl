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
	my($csv) = @_;

	my(%data);

	for my $kind (qw/attribute_types attributes flower_locations flowers images notes urls/)
	{
		$data{$kind} = read_csv_file($csv, $kind);
	}

	for my $key (sort keys %data)
	{
		say "Table: $key. Row count: ", scalar(@{$data{$key} });
	}

	my($file_name) = 'data/attributes.1.csv';

	open(my $fh, '>:encoding(utf-8)', $file_name) || die "Can't open(> $file_name): $!";

	$csv -> combine(qw/common_name attribute_name range/);

	print $fh $csv -> string, "\n";

	my($attribute_name);
	my($common_name);
	my($range);

	for my $attribute (@{$data{attributes} })
	{
		$common_name = $$attribute{common_name};

		for my $attribute_type (sort{$$a{name} cmp $$b{name} } @{$data{attribute_types} })
		{
			$attribute_name	= $$attribute_type{name};
			$range			= $$attribute{range};

			if ($attribute_name eq 'edible')
			{
				$range = 'No' if ($range eq '');
			}
			else
			{
				$range = 'Unknown' if ($range eq '');
			}

			$csv -> combine
			(
				$common_name,
				$attribute_name,
				$range,
			);

			print $fh $csv -> string, "\n";
		}
	}

	close($fh);

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
