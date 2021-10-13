#!/usr/bin/env perl

use 5.30.0;
use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.
use open      qw(:std :utf8); # Undeclared streams in UTF-8.

use Data::Dumper::Concise; # For Dumper.

use File::Slurper 'read_lines';

use Encode ':fallback_all';

use Text::CSV;

# -----------------------------------------------

sub process
{
	my($file_name, $fix_list) = @_;

} # End of process.

# -----------------------------------------------

sub read_csv_file
{
	my($path, $set)	= @_;
	my($count)		= 0;
	my($csv)		= Text::CSV -> new;

	my($column_names);
	my($item);

	open(my $fh_in, '<', "data/$path") || die "Can't open($path): $!\n";

	while (my $line = $csv -> getline($fh_in) )
	{
		$count++;

		if ($count == 1)
		{
			$column_names = [@$line]; # Not $column_names = $line!!!
		}
		else
		{
			for my $i (0 .. $#$column_names)
			{
				$$item{$$column_names[$i]} = $$line[$i];
			}

			push @$set, {%$item};
		}
	}

	close $fh_in;

}	# End of read_csv_file.

# -----------------------------------------------

sub write_csv_file
{
	my($path, $attributes, $column_names)	= @_;
	my($count)	= 0;
	my($csv)	= Text::CSV -> new;

	say "Writing $path";

	open(my $fh_out, ">:encoding(UTF_8)", $path);

	my($status) = $csv->say($fh_out, $column_names);

	if (! $status)
	{
		say "$count: Failed to write header";
	}

	my($row);

	for my $attr (@$attributes)
	{
		$count++;

		$row	= [map{$$attr{$_} } @$column_names];
		$status = $csv->say($fh_out, $row);

		if (! $status)
		{
			say "$count: Failed to write $$attr{common_name}";
		}
	}

	close $fh_out;

}	# End of write_csv_file.

# -----------------------------------------------

my(@csv_file_names)		= qw/attributes flowers.garden flower_locations flowers
							flowers.pipe flowers.web images notes urls/;
my(%fix_file_names)		= (aliases => 'rename.aliases.csv', common_names => 'rename.common_names.csv');
my(%fix_lists)			= (aliases => [], common_names => []);

for my $type (keys %fix_file_names)
{
	read_csv_file($fix_file_names{$type}, $fix_lists{$type});

	say "$type. fix file: $fix_file_names{$type}. ";
	say "$$_{old_text} => $$_{new_text}" for @{$fix_lists{$type} };
	say '';
}
