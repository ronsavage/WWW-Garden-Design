package WWW::Garden::Design::Util::Import;

use feature 'say';
use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Dumper::Concise; # For Dumper().

use File::Slurper qw/read_text/;

use FindBin;

use WWW::Garden::Design::Database;

use Mojo::DOM;
use Mojo::Log;

use Moo;

use Text::CSV::Encoded;

extends qw/WWW::Garden::Design::Database::Base/;

our $VERSION = '1.00';

# -----------------------------------------------

sub BUILD
{
	my($self)		= @_;
	my($log_path)	= "$ENV{HOME}/perl.modules/WWW-Garden-Design/log/development.log";

	$self -> db
	(
		WWW::Garden::Design::Database -> new
		(
			logger => Mojo::Log -> new(path => $log_path)
		)
	);

}	# End of BUILD.

# -----------------------------------------------

sub parse_imagemagick_color_names
{
	my($self)		= @_;
	my($in_file)	= 'data/ImageMagick.Color.Names.html';
	my($dom)		= Mojo::DOM -> new(read_text($in_file) );

	my($td_count);

	for my $node ($dom -> at('table[class="table table-condensed table-striped"]') -> descendant_nodes -> each)
	{
		# Select the heading's tr.

		if ($node -> matches('tr') )
		{
			$td_count = $node -> children -> size;

			last;
		}
	}

	my($codes)	= [];
	my($count)	= -1;

	my($content, $code);
	my($nodule);

	for my $node ($dom -> at('table[class="table table-condensed table-striped"]') -> descendant_nodes -> each)
	{
		next if (! $node -> matches('td') );

		$count++;

		if ( ($count % $td_count) == 0)
		{
			$content	= $node -> content;
			$content	=~ s/[\s]+/ /g;
			$code		= {color => $content, name => '', rbg => '', hex => 0};
		}
		elsif ( ($count % $td_count) == 1)
		{
			$$code{name}	= $node -> content;
			$$code{name}	=~ s/[\s]+/ /g;
		}
		elsif ( ($count % $td_count) == 2)
		{
			$$code{rbg}	= $node -> content;
			$$code{rbg}	=~ s/[\s]+/ /g;
			$$code{rbg}	=~ s/\(\s(\d)/\($1/;
		}
		elsif ( ($count % $td_count) == 3)
		{
			$$code{hex}	= $node -> content;
			$$code{hex}	=~ s/[\s]+/ /g;

			push @$codes, $code;
		}
	}

	@$codes = sort{$$a{name} cmp $$b{name} } @$codes;

	for my $item (@$codes)
	{
		say "Mismatch. name: $$item{name}. color: $$item{color}" if ($$item{name} ne $$item{color});
	}

	open(my $fh, '>', 'data/colors.csv');
	print $fh qq|"color","hex","name","rgb"\n|;
	print $fh map{qq|"$$_{color}","$$_{hex}","$$_{name}","$$_{rbg}"\n|} @$codes;
	close $fh;

	return $codes;

} # End of parse_imagemagick_color_names.

# -----------------------------------------------

sub populate_all_tables
{
	my($self) = @_;

	$self -> db -> logger -> debug('Populating all tables');

	my($path) = "$FindBin::Bin/../data/flowers.csv";
	my($csv)  = Text::CSV::Encoded -> new
	({
		allow_whitespace => 1,
		encoding_in      => 'utf-8',
	});

	my(%attribute_type_keys);
	my(%color_keys);
	my(%flower_keys);
	my(%garden_keys);
	my(%object_keys);

	$self -> populate_attribute_types_table($path, $csv, \%attribute_type_keys);
	$self -> populate_colors_table($path, $csv, \%color_keys);
	$self -> populate_flowers_table($path, $csv, \%flower_keys);
	$self -> populate_gardens_table($path, $csv, \%flower_keys, \%garden_keys);
	$self -> populate_flower_locations_table($path, $csv, \%flower_keys, \%garden_keys);
	$self -> populate_objects_table($path, $csv, \%color_keys, \%object_keys);
	$self -> populate_object_locations_table($path, $csv, \%garden_keys, \%object_keys);
	$self -> populate_attributes_table($path, $csv, \%attribute_type_keys, \%flower_keys);
	$self -> populate_notes_table($path, $csv, \%flower_keys);
	$self -> populate_images_table($path, $csv, \%flower_keys);
	$self -> populate_urls_table($path, $csv, \%flower_keys);

	# Return 0 for OK and 1 for error.

	return 0;

}	# End of populate_all_tables.

# -----------------------------------------------

sub populate_attributes_table
{
	my($self, $path, $csv, $attribute_type_keys, $flower_keys) = @_;
	my($table_name) = 'attributes';
	$path           =~ s/flowers/$table_name/;

	open(my $io, '<', $path) || die "Can't open($path): $!\n";

	$csv -> column_names($csv -> getline($io) );

	my($count) = 0;

	for my $item (@{$csv -> getline_hr_all($io) })
	{
		$count++;

		for my $column (qw/common_name attribute_name attribute_values/)
		{
			if (! defined $$item{$column})
			{
				$self -> db -> logger -> error("$table_name. Row: $count. Column $column undefined");
			}
		}

		if (! defined $$attribute_type_keys{$$item{attribute_name} })
		{
			$self -> db -> logger -> error("$table_name. Row: $count. Attribute name '$$item{attribute_name}' undefined");
		}

		if (! defined $$flower_keys{$$item{common_name} })
		{
			$self -> db -> logger -> error("$table_name. Row: $count. Common name '$$item{common_name}' undefined");
		}

		$self -> db -> insert_hashref
		(
			$table_name,
			{
				attribute_type_id	=> $$attribute_type_keys{$$item{attribute_name} },
				flower_id			=> $$flower_keys{$$item{common_name} },
				values				=> $$item{attribute_values},
			}
		);
	}

	close $io;

	$self -> db -> logger -> info("Read $count records into '$table_name'");

}	# End of populate_attributes_table.

# -----------------------------------------------

sub populate_attribute_types_table
{
	my($self, $path, $csv, $attribute_type_keys) = @_;
	my($table_name) = 'attribute_types';
	$path           =~ s/flowers/$table_name/;

	open(my $io, '<', $path) || die "Can't open($path): $!\n";

	$csv -> column_names($csv -> getline($io) );

	my($count) = 0;

	for my $item (@{$csv -> getline_hr_all($io) })
	{
		$count++;

		for my $column (qw/menu name sequence/)
		{
			if (! defined $$item{$column})
			{
				$self -> db -> logger -> error("$table_name. Row: $count. Column $column undefined");
			}
		}

		$$attribute_type_keys{$$item{name} } = $self -> db -> insert_hashref
		(
			$table_name,
			{
				menu		=> $$item{menu},
				name		=> $$item{name},
				sequence	=> $$item{sequence},
			}
		);
	}

	close $io;

	$self -> db -> logger -> info("Read $count records into '$table_name'");

}	# End of populate_attribute_types_table.

# -----------------------------------------------

sub populate_colors_table
{
	my($self, $path, $csv, $color_keys) = @_;
	my($table_name) = 'colors';
	$path           =~ s/flowers/$table_name/;

	open(my $io, '<', $path) || die "Can't open($path): $!\n";

	$csv -> column_names($csv -> getline($io) );

	my($count) = 0;

	for my $item (@{$csv -> getline_hr_all($io) })
	{
		$count++;

		for my $column (qw/color hex name rgb/)
		{
			if (! defined $$item{$column})
			{
				$self -> db -> logger -> error("$table_name. Row: $count. Column $column undefined");
			}
		}

		$$color_keys{$$item{hex} } = $self -> db -> insert_hashref
		(
			$table_name,
			{
				color	=> $$item{color},
				hex		=> $$item{hex},
				name	=> $$item{name},
				rgb		=> $$item{rgb},
			}
		);
	}

	close $io;

	$self -> db -> logger -> info("Read $count records into '$table_name'");

}	# End of populate_colors_table.

# -----------------------------------------------

sub populate_flower_locations_table
{
	my($self, $path, $csv, $flower_keys, $garden_keys) = @_;
	my($table_name) = 'flower_locations';
	$path           =~ s/flowers/$table_name/;

	open(my $io, '<', $path) || die "Can't open($path): $!\n";

	$csv -> column_names($csv -> getline($io) );

	my($count)	= 0;
	my($max_x)	= 0;
	my($max_y)	= 0;

	my(@xy, $x);
	my($y);

	for my $item (@{$csv -> getline_hr_all($io) })
	{
		$count++;

		for my $column (qw/common_name garden_name xy/)
		{
			if (! defined $$item{$column})
			{
				$self -> db -> logger -> error("$table_name. Row: $count. Column $column undefined");
			}
		}

		next if (length($$item{xy}) == 0);

		if (! defined $$flower_keys{$$item{common_name} })
		{
			$self -> db -> logger -> error("$table_name. Row: $count. Common name '$$item{common_name}' undefined");

			next;
		}

		if (! defined $$garden_keys{$$item{garden_name} })
		{
			$self -> db -> logger -> error("$table_name. Row: $count. Garden '$$item{garden_name}' undefined");

			next;
		}

		@xy = split(/\s/, $$item{xy});

		for my $i (0 .. $#xy)
		{
			($x, $y)	= split(/,/, $xy[$i]);
			$max_x		= $x if ($x > $max_x);
			$max_y		= $y if ($y > $max_y);

			$self -> db -> insert_hashref
			(
				$table_name,
				{
					flower_id	=> $$flower_keys{$$item{common_name} },
					garden_id	=> $$garden_keys{$$item{garden_name} },
					x			=> $x,
					y			=> $y,
				}
			);
		}
	}

	close $io;

	$self -> db -> logger -> info("Max (x, y) = ($max_x, $max_y)");
	$self -> db -> logger -> info("Read $count records into '$table_name'");

}	# End of populate_flower_locations_table.

# -----------------------------------------------

sub populate_flowers_table
{
	my($self, $path, $csv, $flower_keys) = @_;
	my($table_name) = 'flowers';

	open(my $io, '<', $path) || die "Can't open($path): $!\n";

	$csv -> column_names($csv -> getline($io) );

	my($count)	= 0;
	my($lines)	= $csv -> getline_hr_all($io);

	# Stockpile some info we'll need. In particular we need %scientific_name
	# so we can generate the pig_latin column in the flowers table.

	my($common_name, %common_name);
	my($scientific_name, %scientific_name);

	for my $item (@$lines)
	{
		$count++;

		for my $column (qw/aliases common_name scientific_name height width/)
		{
			if (! defined $$item{$column})
			{
				$self -> db -> logger -> error("$table_name. Row: $count. Column $column undefined");
			}
		}

		$common_name		= $$item{common_name};
		$scientific_name	= $$item{scientific_name};

		if ($common_name{$common_name})
		{
			$self -> db -> logger -> info("$table_name. Row: $count. Duplicate common_name: $common_name");
		}

		if ($scientific_name{$scientific_name})
		{
			$self -> db -> logger -> info("$table_name. Row: $count. Duplicate scientific_name: $scientific_name");
		}

		$common_name{$common_name}			= 0 if (! $common_name{$common_name});
		$common_name{$common_name}			+= 1;
		$scientific_name{$scientific_name}	= 0 if (! $scientific_name{$scientific_name});
		$scientific_name{$scientific_name}	+= 1;
	}

	my($pig_latin);

	for my $item (@$lines)
	{
		$common_name				= $$item{common_name};
		$scientific_name			= $$item{scientific_name};
		$pig_latin					= $self -> db -> generate_pig_latin_from_scientific_name($lines, $scientific_name, $common_name);
		$$flower_keys{$common_name}	= $self -> db -> insert_hashref
		(
			$table_name,
			{
				aliases			=> $$item{aliases},
				common_name		=> $common_name,
				pig_latin		=> $pig_latin,
				scientific_name	=> $scientific_name,
				height			=> $$item{height},
				width			=> $$item{width},
			}
		);
	}

	close $io;

	$self -> db -> logger -> info("Read $count records into '$table_name'");

}	# End of populate_flowers_table.

# -----------------------------------------------

sub populate_gardens_table
{
	my($self, $path, $csv, $flower_keys, $garden_keys) = @_;
	my($table_name) = 'gardens';
	$path           =~ s/flowers/$table_name/;

	open(my $io, '<', $path) || die "Can't open($path): $!\n";

	$csv -> column_names($csv -> getline($io) );

	my($count)	= 0;
	my($max_x)	= 0;
	my($max_y)	= 0;

	my(@xy, $x);
	my($y);

	for my $item (@{$csv -> getline_hr_all($io) })
	{
		$count++;

		for my $column (qw/garden_name description/)
		{
			if (! defined $$item{$column})
			{
				$self -> db -> logger -> error("$table_name. Row: $count. Column $column undefined");
			}
		}

		$$garden_keys{$$item{garden_name} } = $self -> db -> insert_hashref
		(
			$table_name,
			{
				description	=> $$item{description},
				name		=> $$item{garden_name},
			}
		);
	}

	close $io;

	$self -> db -> logger -> info("Read $count records into '$table_name'");

}	# End of populate_gardens_table.

# -----------------------------------------------

sub populate_images_table
{
	my($self, $path, $csv, $flower_keys) = @_;
	my($table_name) = 'images';
	$path           =~ s/flowers/$table_name/;

	open(my $io, '<', $path) || die "Can't open($path): $!\n";

	$csv -> column_names($csv -> getline($io) );

	my($count) = 0;

	for my $item (@{$csv -> getline_hr_all($io) })
	{
		$count++;

		for my $column (qw/common_name description file_name sequence/)
		{
			if (! defined $$item{$column})
			{
				$self -> db -> logger -> error("$table_name. Row: $count. Column $column undefined");
			}
		}

		if (! defined $$flower_keys{$$item{common_name} })
		{
			$self -> db -> logger -> error("$table_name. Row: $count. Common name '$$item{common_name}' undefined");

			next;
		}

		$self -> db -> insert_hashref
		(
			$table_name,
			{
				flower_id	=> $$flower_keys{$$item{common_name} },
				description	=> $$item{description},
				file_name	=> $$item{file_name},
				sequence	=> $$item{sequence},
			}
		);
	}

	close $io;

	$self -> db -> logger -> info("Read $count records into '$table_name'");

}	# End of populate_images_table.

# -----------------------------------------------

sub populate_notes_table
{
	my($self, $path, $csv, $flower_keys) = @_;
	my($table_name) = 'notes';
	$path           =~ s/flowers/$table_name/;

	open(my $io, '<', $path) || die "Can't open($path): $!\n";

	$csv -> column_names($csv -> getline($io) );

	my($count) = 0;

	for my $item (@{$csv -> getline_hr_all($io) })
	{
		$count++;

		for my $column (qw/common_name note sequence/)
		{
			if (! defined $$item{$column})
			{
				$self -> db -> logger -> error("$table_name. Row: $count. Column $column undefined");
			}
		}

		if (! defined $$flower_keys{$$item{common_name} })
		{
			$self -> db -> logger -> error("$table_name. Row: $count. Common name '$$item{common_name}' undefined");

			next;
		}

		$self -> db -> insert_hashref
		(
			$table_name,
			{
				flower_id	=> $$flower_keys{$$item{common_name} },
				note		=> $$item{note},
				sequence	=> $$item{sequence},
			}
		);
	}

	close $io;

	$self -> db -> logger -> info("Read $count records into '$table_name'");

}	# End of populate_notes_table.

# -----------------------------------------------

sub populate_object_locations_table
{
	my($self, $path, $csv, $garden_keys, $object_keys) = @_;
	my($table_name) = 'object_locations';
	$path           =~ s/flowers/$table_name/;

	open(my $io, '<', $path) || die "Can't open($path): $!\n";

	$csv -> column_names($csv -> getline($io) );

	my($count)	= 0;
	my($max_x)	= 0;
	my($max_y)	= 0;

	my(@xy, $x);
	my($y);

	for my $item (@{$csv -> getline_hr_all($io) })
	{
		$count++;

		for my $column (qw/name garden_name xy/)
		{
			if (! defined $$item{$column})
			{
				$self -> db -> logger -> error("$table_name. Row: $count. Column $column undefined");
			}
		}

		next if (length($$item{xy}) == 0);

		@xy = split(/\s/, $$item{xy});

		for my $i (0 .. $#xy)
		{
			($x, $y)	= split(/,/, $xy[$i]);
			$max_x		= $x if ($x > $max_x);
			$max_y		= $y if ($y > $max_y);

			$self -> db -> insert_hashref
			(
				$table_name,
				{
					garden_id	=> $$garden_keys{$$item{garden_name} },
					object_id	=> $$object_keys{$$item{name} },
					x			=> $x,
					y			=> $y,
				}
			);
		}
	}

	close $io;

	$self -> db -> logger -> info("Max (x, y) = ($max_x, $max_y)");
	$self -> db -> logger -> info("Read $count records into '$table_name'");

}	# End of populate_object_locations_table.

# -----------------------------------------------

sub populate_objects_table
{
	my($self, $path, $csv, $color_keys, $object_keys) = @_;
	my($table_name) = 'objects';
	$path           =~ s/flowers/$table_name/;

	open(my $io, '<', $path) || die "Can't open($path): $!\n";

	$csv -> column_names($csv -> getline($io) );

	my($count) = 0;

	for my $item (@{$csv -> getline_hr_all($io) })
	{
		$count++;

		for my $column (qw/hex name/)
		{
			if (! defined $$item{$column})
			{
				$self -> db -> logger -> error("$table_name. Row: $count. Column $column undefined");
			}
		}

		$$object_keys{$$item{name} } = $self -> db -> insert_hashref
		(
			$table_name,
			{
				color_id	=> $$color_keys{$$item{hex} },
				name		=> $$item{name},
			}
		);
	}

	close $io;

	$self -> db -> logger -> info("Read $count records into '$table_name'");

}	# End of populate_objects_table.

# -----------------------------------------------

sub populate_urls_table
{
	my($self, $path, $csv, $flower_keys) = @_;
	my($table_name) = 'urls';
	$path           =~ s/flowers/$table_name/;

	open(my $io, '<', $path) || die "Can't open($path): $!\n";

	$csv -> column_names($csv -> getline($io) );

	my($count) = 0;

	for my $item (@{$csv -> getline_hr_all($io) })
	{
		$count++;

		for my $column (qw/common_name sequence url/)
		{
			if (! defined $$item{$column})
			{
				$self -> db -> logger -> error("$table_name. Row: $count. Column $column undefined");
			}
		}

		if (! defined $$flower_keys{$$item{common_name} })
		{
			$self -> db -> logger -> error("$table_name. Row: $count. Common name '$$item{common_name}' undefined");

			next;
		}

		$self -> db -> insert_hashref
		(
			$table_name,
			{
				flower_id	=> $$flower_keys{$$item{common_name} },
				sequence	=> $$item{sequence},
				url			=> $$item{url},
			}
		);
	}

	close $io;

	$self -> db -> logger -> info("Read $count records into '$table_name'");

}	# End of populate_urls_table.

# -----------------------------------------------

1;
