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

sub read_csv_file
{
	my($path, $set)	= @_;
	my($count)		= 0;
	my($csv)		= Text::CSV -> new;

	my($column_names);
	my($item);

	open(my $fh_in, '<', $path) || die "Can't open($path): $!\n";

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

			#$$item{aliases}			= Encode::encode('UTF-8', $$item{aliases}, DIE_ON_ERR | LEAVE_SRC);
			#$$item{common_name}		= Encode::encode('UTF-8', $$item{common_name}, DIE_ON_ERR | LEAVE_SRC);
			#$$item{scientific_name}	= Encode::encode('UTF-8', $$item{scientific_name}, DIE_ON_ERR | LEAVE_SRC);

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

my($attributes)		= [];
my(@column_names)	= qw/common_name attribute_name range/;
my($count)			= 0;
my($flowers)		= [];

read_csv_file('data/attributes.csv', $attributes);
read_csv_file('data/flowers.csv', $flowers);

my($common_name);

for my $attr (@$attributes)
{
	$count++;

	$common_name = $$attr{common_name};

	for my $flower (@$flowers)
	{
		if ($common_name =~ /$$flower{common_name} \d/)
		{
			$$attr{common_name} = $$flower{common_name};

			say "$count. Match. $common_name";
		}

#		if ($common_name =~ /$$flower{scientific_name} \d/)
#		{
#			$$attr{common_name} = $$flower{common_name};
#
#			say "$count. Match. $common_name";
#		}
	}
}

write_csv_file('data/attributes.1.csv', $attributes, \@column_names);
