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

	open(my $fh_in, '<', "data/$path.csv") || die "Can't open($path): $!\n";

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

my(%csv_files) =
(
	attributes =>
	{
		name	=> 'attributes',
		set		=> [],
	},
	flower_locations =>
	{
		name	=> 'flower_locations',
		set		=> [],
	},
	flower_garden =>
	{
		name	=> 'flowers.garden',
		set		=> [],
	},
	flower_pipe =>
	{
		name	=> 'flowers.pipe',
		set		=> [],
	},
	flower_web =>
	{
		name	=> 'flowers.web',
		set		=> [],
	},
	flowers =>
	{
		name	=> 'flowers',
		set		=> [],
	},
	images =>
	{
		name	=> 'images',
		set		=> [],
	},
	notes =>
	{
		name	=> 'notes',
		set		=> [],
	},
	urls =>
	{
		name	=> 'urls',
		set		=> [],
	},
);
my(%fix_files) =
(
	aliases =>
	{
		name	=> 'rename.aliases',
		set		=> [],
	},
	common_names =>
	{
		name	=> 'rename.common_names',
		set		=> [],
	}
);

for my $kind (sort keys %fix_files)
{
	read_csv_file($fix_files{$kind}{name}, $fix_files{$kind}{set});

	say "$kind. fix file: $fix_files{$kind}{name}. ",
		"$kind. record count: @{[$#{$fix_files{$kind}{set} } + 1]}. ";
	#say "$$_{old_text} => $$_{new_text}" for @{$fix_files{$kind}{set} };
	say '';
}

my($count) = 0;

my(@fix_set);

for my $type (sort keys %csv_files)
{
	read_csv_file($csv_files{$type}{name}, $csv_files{$type}{set});

	next if ($type ne 'attributes');

	say "$type. csv file: $csv_files{$type}{name}. ",
		"$type. record count: @{[$#{$csv_files{$type}{set} } + 1]}. ";
	#say "$$_{old_text} => $$_{new_text}" for @{$csv_files{$type}{set} };
	say '';

	@fix_set = @{$fix_files{common_names}{set} };

	say "$type. Processing @{[$#fix_set + 1]} patches for $type";

	for my $item (@{$csv_files{$type}{set} })
	{
		#say "$type. Testing $$item{common_name}";

		for my $string (@fix_set)
		{
			#say "\t$type. Checking $$string{old_text}";

			if ($$string{old_text} eq $$item{common_name})
			{
				$count++;

				say "$type. Match $$string{old_text}";
			}
		}
	}
}
