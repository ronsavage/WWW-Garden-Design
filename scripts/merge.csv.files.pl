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
	my($row);

	open(my $fh_in, '<:encoding(UTF-8)', $path) || die "Can't open($path): $!\n";

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
				$$row{$$column_names[$i]} = $$line[$i];
			}

			$$row{aliases}			= Encode::encode('UTF-8', $$row{aliases}, DIE_ON_ERR | LEAVE_SRC);
			$$row{common_name}		= Encode::encode('UTF-8', $$row{common_name}, DIE_ON_ERR | LEAVE_SRC);
			$$row{scientific_name}	= Encode::encode('UTF-8', $$row{scientific_name}, DIE_ON_ERR | LEAVE_SRC);

			push @$set, {%$row};
		}
	}

	close $fh_in;

}	# End of read_csv_file.

# -----------------------------------------------

sub read_pipe_file
{
	my($path, $set)	= @_;
	my($count)		= 0;
	my($csv)		= Text::CSV -> new;
	my(@lines)		= read_lines($path);
	$path			=~ s/txt$/csv/;

	my($column_names);
	my($row);

	open(my $fh_out, ">:encoding(UTF_8)", $path);

	while (my $line = shift @lines)
	{
		$count++;

		if ($count == 1)
		{
			$column_names = [split(/\|/, $line)];

			$csv->say($fh_out, $column_names);
		}
		else
		{
			$row = [split(/\|/, $line)];

			$csv->say($fh_out, $row);

		}
	}

	close $fh_out;

}	# End of read_pipe_file.

# -----------------------------------------------

my($garden)	= [];
my($pipe)	= [];
my($web)	= [];

read_csv_file('data/flowers.garden.csv', $garden);
read_csv_file('data/flowers.pipe.csv', $pipe);
read_csv_file('data/flowers.web.csv', $web);

say 'Record counts: ', @{[$#$garden + 1]}, '. ', @{[$#$pipe + 1]}, '. ', @{[$#$web + 1]};
#say "$_: " . Dumper($$garden[$_])	for (0 .. 1);
#say "$_: " . Dumper($$pipe[$_])	for (0 .. 1);
#say "$_: " . Dumper($$web[$_])		for (0 .. 1);

my(@garden_names) = qw/common_name scientific_name aliases height width publish/;

my($common_name);
my(%garden);
my(%record);

for (@$garden)
{
	$common_name = $$_{common_name};

	if (defined $garden{$common_name})
	{
		say "Garden. Duplicate name: $common_name";
	}

	%record = ();

	for my $name (@garden_names)
	{
		$record{$name} = $$_{$name};
	}

	$garden{$common_name} = {%record};
}

say 'Key counts: ', @{[scalar keys %garden]}, '. ';

my(@pipe_names) = qw/id aliases common_name height max_height max_width min_height min_width pig_latin publish scientific_name width/;

my(%pipe);

for (@$pipe)
{
	$common_name = $$_{common_name};

	if (defined $pipe{$common_name})
	{
		say "Pipe. Duplicate name: $common_name";
	}

	%record = ();

	for my $name (@pipe_names)
	{
		$record{$name} = $$_{$name};
	}

	$pipe{$common_name} = {%record};
}

say 'Key counts: ', @{[scalar keys %pipe]}, '. ';

my(@web_names) = qw/kind scientific_name common_name aliases planted thumbnail/;

my(%web);

for (@$web)
{
	$common_name = $$_{common_name};

	if (defined $web{$common_name})
	{
		say "Web. Duplicate name: $common_name";
	}

	%record = ();

	for my $name (@web_names)
	{
		$record{$name} = $$_{$name};
	}

	$web{$common_name} = {%record};
}

say 'Key counts: ', @{[scalar keys %web]}, '. ';

