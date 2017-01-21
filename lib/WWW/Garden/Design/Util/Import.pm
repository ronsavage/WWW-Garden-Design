package WWW::Garden::Design::Util::Import;

use feature 'say';
use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use File::Slurper qw/read_text/;

use FindBin;

use WWW::Garden::Design::Database;

use Mojo::DOM;
use Mojo::Log;

use Moo;

use Text::CSV::Encoded;

extends qw/WWW::Garden::Design::Database::Base/;

our $VERSION = '0.95';

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
	my(%flower_keys);
	my(%garden_keys);
	my(%object_keys);
	my(%property_keys);

	$self -> populate_attribute_types_table($path, $csv, \%attribute_type_keys);
	$self -> populate_constants_table($path, $csv);
	$self -> populate_flowers_table($path, $csv, \%flower_keys);
	$self -> populate_properties_table($path, $csv, \%property_keys);
	$self -> populate_gardens_table($path, $csv, \%garden_keys, \%property_keys);
	$self -> populate_flower_locations_table($path, $csv, \%flower_keys, \%garden_keys);
	$self -> populate_objects_table($path, $csv, \%object_keys);
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

		for my $column (qw/attribute_name common_name range/)
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
				range				=> $$item{range},
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

		for my $column (qw/name range sequence/)
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
				name		=> $$item{name},
				range		=> $$item{range},
				sequence	=> $$item{sequence},
			}
		);
	}

	close $io;

	$self -> db -> logger -> info("Read $count records into '$table_name'");

}	# End of populate_attribute_types_table.

# -----------------------------------------------

sub populate_constants_table
{
	my($self, $path, $csv) = @_;
	my($table_name) = 'constants';
	$path           =~ s/flowers/$table_name/;

	open(my $io, '<', $path) || die "Can't open($path): $!\n";

	$csv -> column_names($csv -> getline($io) );

	my($count) = 0;

	for my $item (@{$csv -> getline_hr_all($io) })
	{
		$count++;

		for my $column (qw/name value/)
		{
			if (! defined $$item{$column})
			{
				$self -> db -> logger -> error("$table_name. Row: $count. Column $column undefined");
			}
		}

		$self -> db -> insert_hashref
		(
			$table_name,
			{
				name	=> $$item{name},
				value	=> $$item{value},
			}
		);
	}

	close $io;

	$self -> db -> logger -> info("Read $count records into '$table_name'");

}	# End of populate_constants_table.

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
	my($max_height, $min_height, $max_width, $min_width);
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
		($max_height, $min_height)	= $self -> validate_size($table_name, $count, lc $self -> db -> trim($$item{height}), lc $self -> db -> trim($$item{height}) );
		($max_width, $min_width)	= $self -> validate_size($table_name, $count, lc $self -> db -> trim($$item{width}), lc $self -> db -> trim($$item{width}) );
		$$flower_keys{$common_name}	= $self -> db -> insert_hashref
		(
			$table_name,
			{
				aliases			=> $$item{aliases},
				common_name		=> $common_name,
				pig_latin		=> $pig_latin,
				scientific_name	=> $scientific_name,
				height			=> $$item{height},
				max_height		=> $max_height,
				min_height		=> $min_height,
				max_width		=> $max_width,
				min_width		=> $min_width,
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
	my($self, $path, $csv, $garden_keys, $property_keys) = @_;
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

		for my $column (qw/property_name garden_name description/)
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
				property_id	=> $$property_keys{$$item{property_name} },
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
	my($self, $path, $csv, $object_keys) = @_;
	my($table_name) = 'objects';
	$path           =~ s/flowers/$table_name/;

	open(my $io, '<', $path) || die "Can't open($path): $!\n";

	$csv -> column_names($csv -> getline($io) );

	my($count) = 0;

	for my $item (@{$csv -> getline_hr_all($io) })
	{
		$count++;

		for my $column (qw/hex_color name/)
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
				hex_color	=> $$item{hex_color},
				name		=> $$item{name},
			}
		);
	}

	close $io;

	$self -> db -> logger -> info("Read $count records into '$table_name'");

}	# End of populate_objects_table.

# -----------------------------------------------

sub populate_properties_table
{
	my($self, $path, $csv, $property_keys) = @_;
	my($table_name) = 'properties';
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

		for my $column (qw/name description/)
		{
			if (! defined $$item{$column})
			{
				$self -> db -> logger -> error("$table_name. Row: $count. Column $column undefined");
			}
		}

		$$property_keys{$$item{name} } = $self -> db -> insert_hashref
		(
			$table_name,
			{
				description	=> $$item{description},
				name		=> $$item{name},
			}
		);
	}

	close $io;

	$self -> db -> logger -> info("Read $count records into '$table_name'");

}	# End of populate_properties_table.

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

sub validate_size
{
	my($self, $table_name, $count, $value) = @_;
	my($max_value)	= '';
	my($min_value)	= '';

	if ($value ne '')
	{
		my($unit) = '';

		if ($value =~ /^([0-9]{0,3}(?:[.][0-9]{0,2})?)\s*-\s*([0-9]{0,3}(?:[.][0-9]{0,2})?)\s*(cm|m)$/)
		{
			$max_value	= $2;
			$min_value	= $1;
			$unit		= $3;
		}
		elsif ($value =~ /^([0-9]{0,3}(?:[.][0-9]{0,2})?)\s*(cm|m)$/)
		{
			$max_value	= $1;
			$min_value	= $1;
			$unit		= $2;
		}
		else
		{
			$self -> db -> logger -> info("$table_name. Row: $count. Cannot interpret height or width");
		}

		if ($unit eq 'm')
		{
			# Format as whole cd, i. e. with no decimal places.

			$max_value = sprintf('%.0f', $max_value * 100);
			$min_value = sprintf('%.0f', $min_value * 100);
		}
	}

	return ($max_value, $min_value);

} # End of validate_size.

# -----------------------------------------------

1;
