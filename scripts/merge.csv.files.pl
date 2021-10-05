#!/usr/bin/env perl

use 5.30.0;
use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.
use open      qw(:std :utf8); # Undeclared streams in UTF-8.

use Data::Dumper::Concise; # For Dumper.

use Encode ':fallback_all';

use Text::CSV;

# -----------------------------------------------

sub read_file
{
	my($path)	= @_;
	my($count)	= 0;
	my($csv)	= Text::CSV -> new;

	my($column_names);
	my($row);
	my(@set);

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

			$$row{aliases}					= Encode::encode('UTF-8', $$row{aliases}, DIE_ON_ERR | LEAVE_SRC);
			$$row{common_name}				= Encode::encode('UTF-8', $$row{common_name}, DIE_ON_ERR | LEAVE_SRC);
			$$row{scientific_name}			= Encode::encode('UTF-8', $$row{scientific_name}, DIE_ON_ERR | LEAVE_SRC);

			push @set, {%$row};
		}
	}

	close $fh_in;

	return [@set];

}	# End of read_file.

# -----------------------------------------------

my($garden)	= read_file('data/flowers.garden.csv');
my($web)	= read_file('data/flowers.web.csv');

say 'Record counts: ', @{[$#$garden + 1]}, '. ', @{[$#$web + 1]};
say "$_: " . Dumper($$garden[$_])	for (0 .. 1);
say "$_: " . Dumper($$web[$_])		for (0 .. 1);
