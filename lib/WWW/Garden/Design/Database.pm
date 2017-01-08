package WWW::Garden::Design::Database;

use boolean;
use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Dumper::Concise; # For Dumper().

use DBI;

use DBIx::Simple;

use File::Slurper qw/read_dir/;

use Lingua::EN::Inflect qw/inflect PL_N/; # PL_N: plural of a singular noun.

use Moo;

use Time::HiRes qw/gettimeofday tv_interval/;

use Types::Standard qw/Object HashRef/;

extends qw/WWW::Garden::Design::Util::Config/;

has constants =>
(
	default		=> sub{return {} },
	is			=> 'rw',
	isa			=> HashRef,
	required	=> 0,
);

has dbh =>
(
	is       => 'rw',
	isa      => Object,
	required => 0,
);

has logger =>
(
	is       => 'rw',
	isa      => Object,
	required => 1,
);

has simple =>
(
	is       => 'rw',
	isa      => Object,
	required => 0,
);

our $VERSION = '0.95';

# -----------------------------------------------

sub BUILD
{
	my($self)   = @_;
	my($config) = $self -> config;
	my($attr)   =
	{
		AutoCommit => defined($$config{AutoCommit}) ? $$config{AutoCommit} : 1,
		RaiseError => defined($$config{RaiseError}) ? $$config{RaiseError} : 1,
	};
	my(%driver) =
	(
		mysql_enable_utf8 => qr/dbi:MySQL/i,
		pg_enable_utf8    => qr/dbi:Pg/i,
		sqlite_unicode    => qr/dbi:SQLite/i,
	);

	for my $db (keys %driver)
	{
		if ($$config{dsn} =~ $driver{$db})
		{
			$$attr{$db} = defined($$config{$db}) ? $$config{$db} : 1;
		}
	}

	$self -> dbh(DBI -> connect($$config{dsn}, $$config{username}, $$config{password}, $attr) );
	$self -> dbh -> do('PRAGMA foreign_keys = ON') if ($$config{dsn} =~ /SQLite/i);

	$self -> simple(DBIx::Simple -> new($self -> dbh) );
	$self -> constants($self -> read_constants_table); # Warning. Empty at start of import.

}	# End of BUILD.

# -----------------------------------------------

sub build_error_xml
{
	my($self, $error, $result) = @_;

	$self -> logger -> debug("Database::Library.build_error_xml($error, ...)");

	my(@msg);
	my($value);

	push @msg, {left => 'Field', right => 'Error'};

	for my $field ($result -> invalids)
	{
		$value = $result -> get_original_value($field) || '';

		$self -> logger -> error("Validation error. Field '$field' has an invalid value: $value");

		push @msg, {left => $field, right => "Invalid value: $value"};
	}

	for my $field ($result -> missings)
	{
		$self -> logger -> error("Validation error. Field '$field' is missing");

		push @msg, {left => $field, right => 'Missing value'};
	}

	my($html) = $self -> templater -> render
	(
		'fancy.table.tx',
		{
			data => [@msg],
		}
	);

	return
qq|<response>
	<error>Error: $error</error>
	<html><![CDATA[$html]]></html>
</response>
|;

} # End of build_error_xml.

# -----------------------------------------------

sub build_ok_xml
{
	my($self, $html) = @_;

	$self -> logger -> debug('Database::Library.build_ok_xml(...)');

	return
qq|<response>
	<error></error>
	<html><![CDATA[$html]]></html>
</response>
|;

} # End of build_ok_xml.

# -----------------------------------------------

sub build_simple_error_xml
{
	my($self, $error, $html) = @_;

	$self -> logger -> debug("Database::Library.build_simple_error_xml($error, ...)");

	return
qq|<response>
	<error>Error: $error</error>
	<html><![CDATA[$html]]></html>
</response>
|;

} # End of build_simple_error_xml.

# --------------------------------------------------

sub clean_up_icon_name
{
	my($self, $name)	= @_;
	my($file_name)		= $name =~ s/\s/./gr;

	return $file_name;

} # End of clean_up_icon_name.

# -----------------------------------------------

sub cross_check
{
	my($self)		= @_;
	my($flowers)	= $self -> read_flowers_table;
	my(%dirs)		=
	(
		'doc_flowers' =>
		{
			dir_name	=> "$ENV{DR}/Flowers",
			file_names	=> [],
			name_hash	=> {},
		},
		'doc_images' =>
		{
			dir_name	=> "$ENV{DR}/Flowers/images",
			file_names	=> [],
			name_hash	=> {},
		},
	);

	# Read in the actualy file names.

	my(@dir_list);

	for my $key (sort keys %dirs)
	{
		@dir_list								= read_dir $dirs{$key}{dir_name};
		@dir_list								= sort grep{! -d "$dirs{$key}{dir_name}/$_"} @dir_list; # Can't call sort directly on output of read_dir!
		$dirs{$key}{file_names}					= [@dir_list];
		@{$dirs{$key}{name_hash} }{@dir_list}	= (1) x @dir_list;

		#$self -> logger -> info("File in $key: $_") for sort keys %{$dirs{$key}{name_hash} };
	}

	# Check that the files which ought to be there, are.

	my($count);
	my($common_name);
	my($file_name);
	my($image);
	my($key);
	my($pig_latin);
	my(%real_name);
	my($scientific_name);

	for my $flower (@$flowers)
	{
		$common_name		= $$flower{common_name};
		$scientific_name	= $$flower{scientific_name};
		$pig_latin			= $self -> clean_up_scientific_name($flowers, $scientific_name, $common_name);

		for $key (sort keys %dirs)
		{
			$file_name						= ($key eq 'doc_images') ? "$pig_latin.0.jpg" : "$pig_latin.html";
			$real_name{$key}				= {} if (! $real_name{$key});
			$real_name{$key}{$file_name}	= 1;

			if (! $dirs{$key}{name_hash}{$file_name})
			{
				$self -> logger -> error("1: Missing file in $key: $file_name");
			}
		}

		$key = 'doc_images';

		for $image (sort{$$a{file_name} cmp $$b{file_name} } @{$$flower{images} })
		{
			$file_name						= $$image{file_name};
			$real_name{$key}{$file_name}	= 1;

			if (! $dirs{$key}{name_hash}{$file_name})
			{
				$self -> logger -> error("2: Missing file in doc_images: $file_name");
			}
		}
	}

	# Check for any unexpected files. A file is unexpected if it's not real :-).

	for my $key (sort keys %dirs)
	{
		for my $file_name (@{$dirs{$key}{file_names} })
		{
			if (! $real_name{$key}{$file_name})
			{
				$self -> logger -> error("3: Unexpected file in $key: $file_name");
			}
		}
	}

	# Return 0 for OK and 1 for error.

	return 0;

} # End of cross_check.

# --------------------------------------------------

sub format_height_width
{
	my($self, $height, $width) = @_;

	my($result);

	if ($height)
	{
		if ($width)
		{
			$result = "$height x $width";
		}
		else
		{
			$result = "Height: $height";
		}
	}
	else
	{
		if ($width)
		{
			$result = "Width: $width";
		}
		else
		{
			$result = '';
		}
	}

	return $result;

} # End of format_height_width.

# --------------------------------------------------

sub generate_pig_latin_from_scientific_name
{
	my($self, $flowers, $scientific_name, $common_name) = @_;
	my(@chars)		= split(//, $scientific_name);
	my($pig_latin)	= '';

	for (@chars)
	{
		$pig_latin .= $1 if (m|([-_. a-zA-Z0-9])|)
	}

	$pig_latin	=~ s!^\s!!;
	$pig_latin	=~ s!\s$!!;
	$pig_latin	=~ s!\s!\.!g;

	my(%seen);

	for my $flower (@$flowers)
	{
		$seen{$$flower{scientific_name} } = 0 if (! $seen{$$flower{scientific_name} });

		$seen{$$flower{scientific_name} }++;
	}

	if ($seen{$scientific_name} > 1)
	{
		$pig_latin .= ".$1" if ($common_name =~ /^.+\s(\d+)$/);
	}

	$pig_latin =~ s!\.\.!\.!g;

	return ucfirst lc $pig_latin;

} # End of generate_pig_latin_from_scientific_name.

# -----------------------------------------------

sub get_autocomplete_list
{
	my($self, $context, $type, $key) = @_;
	$key =~ s/\'/\'\'/g; # Since we're using Pg.

	my($result, @result);
	my($sql, %seen);
	my(@value, $value);

	for my $index (keys %$context)
	{
		my($search_column)	= $$context{$index}[0];
		my($table_name)		= $$context{$index}[1];

		# If we're not searching then we're processing the Add screen.
		# In that case, we're only interested in one $index at a time.

		if ( ($type ne 'search') && ($index ne $type) )
		{
			next;
		}

		$sql	= "select $search_column from $table_name where upper($search_column) like '%$key%'";
		$result	= $self -> simple -> query($sql) || die $self -> simple -> error;
		@value	= $result -> flat;

		for $value (@value)
		{
			next if (! defined $value);

			if (! $seen{$value})
			{
				push @result, $value;

				$seen{$value} = 1;
			}
		}
	}

	return [@result];

} # End of get_autocomplete_list.

# --------------------------------------------------

sub get_flower_by_id
{
	my($self, $flower_id)		= @_;
	my($attribute_types_table)	= $self -> read_table('attribute_types');
	my($sql)					= "select * from flowers where id = $flower_id";
	my($set)						= $self -> simple -> query($sql) || die $self -> db -> simple -> error;
	my($flower)				= $set -> hash;

	my(%attribute_type);

	for (@$attribute_types_table)
	{
		$attribute_type{$$_{id} } = $_;
	}

	for my $table_name (qw/attributes flower_locations images notes urls/)
	{
		$$flower{$table_name} = $self -> read_flower_dependencies($table_name, $$flower{id});
	}

	my($attribute);
	my($id);

	# Annotate the attributes with their types.

	for my $i (0 .. $#{$$flower{attributes} })
	{
		$attribute	= $$flower{attributes}[$i];
		$id			= $$attribute{attribute_type_id};

		for my $name (qw/name sequence/)
		{
			$$flower{attributes}[$i]{$name} = $attribute_type{$id}{$name};
		}
	}

	# Return a hashref.

	return $flower;

} # End of get_flower_by_id.

# -----------------------------------------------

sub insert_hashref
{
	my($self, $table_name, $hashref) = @_;

	$self -> simple -> insert($table_name, {map{($_ => $$hashref{$_})} keys %$hashref})
		|| die $self -> simple -> error;

	return $self -> simple -> last_insert_id(undef, undef, $table_name, undef);

} # End of insert_hashref.

# -----------------------------------------------

sub parse_attribute_checkboxes
{
	my($self, $defaults, $search_attributes)	= @_;

	$self -> logger -> debug('Entered Database.parse_attribute_checkboxes()');

	my($attribute_type_names)					= $$defaults{attribute_type_names};
	my($attribute_type_fields)					= $$defaults{attribute_type_fields};

	my($attribute_name, $attribute_value);
	my(%checkboxes);
	my($name);

	# Ensure every checkbox has a value of 'true' and a name like:
	# 'A known attribute type' . '_' . 'A value',
	# where the value is one of the known values for the given type.

	for my $key (keys %$search_attributes)
	{
		# Strip off the leading 'search_'.

		next if (substr($key, 0, 7) ne 'search_');

		$name = substr($key, 7);

		next if ($$search_attributes{$key} ne 'true');

		for my $type_name (@$attribute_type_names)
		{
			if ($name =~ /^($type_name)_(.+)$/)
			{
				# Warning: Because of the s/// you cannot combine these into 1 line
				# such as $result{$1} = $2 =~ s/_/ /gr. I know - I tried.

				$attribute_name		= $1;
				$attribute_value	= $2;
				$attribute_value	=~ s/_/ /g;
				$attribute_value	= 'Semi-dwarf' if ($attribute_value eq 'Semi dwarf');

				for my $type_value (@{$$attribute_type_fields{$type_name} })
				{
					$checkboxes{$attribute_name} = [] if (! $checkboxes{$attribute_name});

					push @{$checkboxes{$attribute_name} }, $attribute_value if ($attribute_value eq $type_value);
				}
			}
		}
	}

	$self -> logger -> debug('Leaving Database.parse_attribute_checkboxes()');

	return \%checkboxes;

} # End of parse_attribute_checkboxes.

# -----------------------------------------------

sub parse_search_attributes
{
	my($self, $defaults, $search_attributes) = @_;

	$self -> logger -> debug('Entered Database.parse_search_attributes()');

	my($checkboxes)			= $self -> parse_attribute_checkboxes($defaults, $search_attributes);
	my(@type_names)			= keys %$checkboxes;
	my($type_name_count)	= scalar @type_names;

	$self -> logger -> debug('checkboxes: ' . Dumper($checkboxes) );

	if ($type_name_count == 0)
	{
		return (false, {});
	}

	my($attributes_table)		= $$defaults{attributes_table};
	my($attribute_types_table)	= $$defaults{attribute_types_table};

	my($all_match);
	my(%candidate_flower_ids);

	# Did the user provide attributes?

	for my $type_name (@type_names)
	{
		my($attribute_type_id) = 0;

		for my $attribute_type (@$attribute_types_table)
		{
			if ($$attribute_type{name} eq $type_name)
			{
				$attribute_type_id = $$attribute_type{id};
			}
		}

		if ($attribute_type_id)
		{
			for my $attribute (@$attributes_table)
			{
				next if ($$attribute{attribute_type_id} != $attribute_type_id);

				$all_match = true;
				my($count) = 0;

				for my $candidate (@{$$checkboxes{$type_name} })
				{
					if ($$attribute{range} !~ /$candidate/)
					{
						$all_match = false;

						last;
					}

					$count++;
				}

#				$self -> logger -> debug("attribute type: $type_name. range: $$attribute{range}. "
#					. "Matches: $count. Checkboxes: " . join(', ', @{$$checkboxes{$type_name} }) )
#					if ($count > 0);

				if ($all_match -> isTrue)
				{
					$candidate_flower_ids{$$attribute{flower_id} } = 1;
				}
			}
		}
	}

	$self -> logger -> debug('Leaving Database.parse_search_attributes()');

	return (true, \%candidate_flower_ids);

} # End of parse_search_attributes.

# -----------------------------------------------

sub parse_search_text
{
	my($self, $search_text)	= @_;

	$self -> logger -> debug('Entered Database.parse_search_text()');

	my($request) =
	{
		error_message	=> '',
		height_provided	=> false,
		lc_search_text	=> lc $search_text,
		search_text		=> $search_text, # Save in original case for display to the user.
		size_provided	=> false,
		text_is_clean	=> true,
		text_provided	=> true,
		width_provided	=> false,
	};
	$search_text = lc $search_text;

	# Test input and return structured result.

	if ($search_text eq '')
	{
		$$request{text_provided} = false;
	}
	elsif ($search_text =~ /^[-a-z0-9. ']+$/) # Use another ' to reset the UltraEdit syntax hiliter.
	{
	}					#		Direction		Operator		Size					Unit
	elsif ($search_text =~ /^(h|height|w|width)\s*([<=>])\s*([0-9]{0,3}(?:[.][0-9]{0,2})?)\s*(cm|m)?$/)
	{
		my($direction) = $1;

		$$request{direction}		= ($direction eq 'height') ? 'h' : ($direction eq 'width') ? 'w' : $direction;
		$$request{height_provided}	= true if ($$request{direction} eq 'h');
		$$request{operator}			= $2;
		$$request{size}				= $3 || 1;
		$$request{size_provided}	= true;
		$$request{unit}				= $4 || 'm';
		$$request{width_provided}	= true if ($$request{direction} eq 'w');

		$self -> logger -> debug("Captured '$$request{direction}' & '$$request{operator}' & '$$request{size}' & '$$request{unit}'");

		if ($$request{unit} eq 'm')
		{
			$$request{size}	*= 100;
			$$request{unit}	= 'cm';
		}
	}
	else
	{
		$$request{error_message}	= 'Unknown chars in text. Check Search FAQ for help with sizes';
		$$request{text_is_clean}	= false;
	}

	$self -> logger -> debug('Leaving Database.parse_search_text()');

	return $request;

} # End of parse_search_text.

# -----------------------------------------------

sub read_constants_table
{
	my($self)		= @_;
	my($constants)	= {};

	# Reorder so we can return a hashref and not an arrayref.

	$$constants{$$_{name} } = $$_{value} for (@{$self -> read_table('constants')});

	return $constants;

} # End of read_constants_table.

# --------------------------------------------------

sub read_flower_dependencies
{
	my($self, $table_name, $flower_id) = @_;
	my($sql)	= "select * from $table_name where flower_id = $flower_id";
	my($set)	= $self -> simple -> query($sql) || die $self -> db -> simple -> error;

	# Return an arrayref of hashrefs.

	return [$set -> hashes];

} # End of read_flower_dependencies.

# --------------------------------------------------

sub read_flowers_table
{
	my($self)					= @_;
	my($constants)				= $self -> constants;
	my($attribute_types_table)	= $self -> read_table('attribute_types');
	my($flower_table)			= $self -> read_table('flowers'); # Avoid 'Deep Recursion'! Don't call read_flowers_table()!

	my(%attribute_type);

	for (@$attribute_types_table)
	{
		$attribute_type{$$_{id} } = $_;
	}

	my($attribute);
	my($id);
	my($pig_latin);
	my($record, @records);
	my($thumbnail);

	for my $flower (@$flower_table)
	{
		# Phase 1: Transfer the flower data.

		$record	= {};

		for my $key (keys %$flower)
		{
			$$record{$key} = $$flower{$key};
		}

		$pig_latin				= $$flower{pig_latin};
		$$record{hxw}			= $self -> format_height_width($$flower{height}, $$flower{width});
		$$record{thumbnail_url}	= "$$constants{homepage_url}$$constants{image_url}/$pig_latin.0.jpg";
		$$record{web_page_url}	= "$$constants{homepage_url}$$constants{flower_url}/$pig_latin.html";

		for my $table_name (qw/attributes flower_locations images notes urls/)
		{
			$$record{$table_name} = $self -> read_flower_dependencies($table_name, $$record{id});
		}

		# Annotate the attributes with their types.

		for my $i (0 .. $#{$$record{attributes} })
		{
			$attribute	= $$record{attributes}[$i];
			$id			= $$attribute{attribute_type_id};

			for my $name (qw/name sequence/)
			{
				$$record{attributes}[$i]{$name} = $attribute_type{$id}{$name};
			}
		}

		# Fix the image urls.

		for my $i (0 .. $#{$$record{images} })
		{
			$$record{images}[$i]{raw_name}	= $$record{images}[$i]{file_name};
			$$record{images}[$i]{file_name}	= "$$constants{homepage_url}$$constants{image_url}/$$record{images}[$i]{file_name}";
		}

		push @records, $record;
	}

	# Return an arrayref of hashrefs.

	return [sort{$$a{common_name} cmp $$b{common_name} } @records];

} # End of read_flowers_table.

# --------------------------------------------------

sub read_object_dependencies
{
	my($self, $table_name, $object_id) = @_;
	my($sql)	= "select * from $table_name where object_id = $object_id";
	my($set)	= $self -> simple -> query($sql) || die $self -> db -> simple -> error;

	# Return an arrayref of hashrefs.

	return [$set -> hashes];

} # End of read_object_dependencies.

# --------------------------------------------------

sub read_objects_table
{
	my($self)			= @_;
	my($constants)		= $self -> constants;
	my($color_table)	= $self -> read_table('colors');

	my(%color_map);

	for my $color (@$color_table)
	{
		$color_map{$$color{id} } = $color;
	}

	my($record, @records);

	for my $object (@{$self -> read_table('objects')})
	{
		# Phase 1: Transfer the object data.

		$record	= {};

		for my $key (keys %$object)
		{
			$$record{$key} = $$object{$key};
		}

		$$record{color}		= $color_map{$$record{color_id} };
		$$record{icon_dir}	= "$$constants{homepage_dir}$$constants{icon_dir}";
		$$record{icon_url}	= "$$constants{homepage_url}$$constants{icon_url}";

		for my $table_name (qw/object_locations/)
		{
			$$record{$table_name} = $self -> read_object_dependencies($table_name, $$record{id});
		}

		push @records, $record;
	}

	# Return an arrayref of hashrefs.

	return [sort{$$a{name} cmp $$b{name} } @records];

} # End of read_objects_table.

# --------------------------------------------------

sub read_table
{
	my($self, $table_name)	= @_;
	my($sql)				= "select * from $table_name";
	my($set)				= $self -> simple -> query($sql) || die $self -> db -> simple -> error;

	# Return an arrayref of hashrefs.

	return [$set -> hashes];

} # End of read_table.

# --------------------------------------------------

sub search
{
	my($self, $defaults, $constants_table, $search_attributes, $search_text) = @_;

	$self -> logger -> debug('Entered Database.search()');

	my($request) = $self -> parse_search_text($self -> trim($search_text) );

#	$self -> logger -> debug('request: ' . Dumper($request) );

	if ($$request{text_is_clean} -> isFalse)
	{
		$$request{time_taken} = 0;

		return ([], $request);
	}

	my($attribute_provided, $wanted_flower_ids)	= $self -> parse_search_attributes($defaults, $search_attributes);
	my($flowers)								= $self -> read_flowers_table;
	my($result_set)								= [];

	my($attribute_match);
	my($flower_id);
	my($item);
	my($match);
	my($pig_latin);
	my($text_match);

	my($start_time) = [gettimeofday];

	for my $flower (@$flowers)
	{
		$flower_id			= $$flower{id};
		$attribute_match	= $$wanted_flower_ids{$flower_id} || 0;
		$text_match			= $$request{size_provided}
								? $$flower{height} && $$request{height_provided} -> isTrue
									? $self -> test_size($defaults, $flower, $request)
									: $$flower{width} && $$request{width_provided} -> isTrue
										? $self -> test_size($defaults, $flower, $request)
										: false # Impossible, presumably.
								: $self -> test_text($flower, $request);

		if ($attribute_provided)
		{
			$match = $$request{text_provided} ? $attribute_match && $text_match : $attribute_match;
		}
		else
		{
			$match = $$request{text_provided} ? $text_match : 0;
		}

		if ($match)
		{
			$pig_latin	= $$flower{pig_latin};
			$item		=
			{
				aliases			=> $$flower{aliases},
				attributes		=> $$flower{attributes},
				common_name		=> $$flower{common_name},
				id				=> $flower_id,
				scientific_name	=> $$flower{scientific_name},
				hxw				=> $self -> format_height_width($$flower{height}, $$flower{width}),
				height			=> $$flower{height},
				pig_latin		=> $pig_latin,
				thumbnail_url	=> "$$constants_table{homepage_url}$$constants_table{image_url}/$pig_latin.0.jpg",
				width			=> $$flower{width},
			};

			push @$result_set, $item;
		}
	}

	$$request{time_taken} = tv_interval($start_time);

	$self -> logger -> info("Match count: @{[$#$result_set + 1]}");
	$self -> logger -> debug('Leaving Database.search()');

	return ([sort{$$a{common_name} cmp $$b{common_name} } @$result_set], $request);

} # End of search.

# -----------------------------------------------

sub test_size
{
	my($self, $defaults, $flower, $request) = @_;
	my($height_latitude)	= $$defaults{constants_table}{height_latitude};
	my($result)				= false;
	my($width_latitude)		= $$defaults{constants_table}{width_latitude};

	my($lower_bound);
	my($upper_bound);

	if ($$request{height_provided} -> isTrue)
	{
		if ($$request{operator} eq '<')
		{
			if ($$flower{max_height} < $$request{size})
			{
				$result = true;
			}
		}
		elsif ($$request{operator} eq '=')
		{
			$height_latitude	= 30 if ($height_latitude <= 0);
			$lower_bound		= $$request{size} - ($$request{size} * $height_latitude / 100);
			$lower_bound		= 0 if ($lower_bound < 0);
			$upper_bound		= $$request{size} + ($$request{size} * $height_latitude / 100);

			if ( ($$flower{min_height} >= $lower_bound) && ($$flower{max_height} <= $upper_bound) )
			{
				$result = true;
			}
		}
		elsif ($$flower{min_height} > $$request{size})
		{
			$result = true;
		}
	}
	elsif ($$request{width_provided} -> isTrue)
	{
		if ($$request{operator} eq '<')
		{
			if ($$flower{max_width} < $$request{size})
			{
				$result = true;
			}
		}
		elsif ($$request{operator} eq '=')
		{
			$width_latitude	= 30 if ($width_latitude <= 0);
			$lower_bound	= $$request{size} - ($$request{size} * $width_latitude / 100);
			$lower_bound	= 0 if ($lower_bound < 0);
			$upper_bound	= $$request{size} + ($$request{size} * $width_latitude / 100);

			if ( ($$flower{min_width} >= $lower_bound) && ($$flower{max_width} <= $upper_bound) )
			{
				$result = true;
			}
		}
		elsif ($$flower{min_width} > $$request{size})
		{
			$result = true;
		}
	}

	return $result;

} # End of test_size.

# -----------------------------------------------

sub test_text
{
	my($self, $flower, $request) = @_;

	return ( (lc($$flower{aliases}) =~ /$$request{lc_search_text}/)
			|| (lc($$flower{common_name}) =~ /$$request{lc_search_text}/)
			|| (lc($$flower{scientific_name}) =~ /$$request{lc_search_text}/) );

} # End of test_text.

# -----------------------------------------------

sub trim
{
	my($self, $value) = @_;
	$value	=~ s/^\s+//;
	$value	=~ s/\s+$//;
	$value	=~ s/\s{2,}/ /g;

	return $value;

} # End of trim.

# --------------------------------------------------

1;
