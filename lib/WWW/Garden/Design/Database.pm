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

sub clean_up_height_width
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

} # End of clean_up_height_width.

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
	my($self, $search_column, $table_name, $key) = @_;
	$key =~ s/\'/\'\'/g;

	# Warning: Do not use 'distinct' in this particular SQL. It then only ever returns 1 row.

	my($sql)    = "select $search_column from $table_name where $search_column ilike '%$key%' order by $search_column";
	my($result) = $self -> simple -> query($sql)
					|| die $self -> simple -> error;

	return [$result -> flat];

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

sub parse_search_attributes
{
	my($self, $attribute_types_table, $attributes_table, $search_attributes, $type_names, $type_name_count) = @_;

	my(%candidate_flower_ids);

	# Did the user provide attributes?

	for my $type_name (@$type_names)
	{
		my($attribute_type_id);

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
				if ( ($$attribute{attribute_type_id} == $attribute_type_id) && ($$attribute{range} =~ /$$search_attributes{$type_name}/) )
				{
					$candidate_flower_ids{$$attribute{flower_id} }				= {} if (!$candidate_flower_ids{$$attribute{flower_id} });
					$candidate_flower_ids{$$attribute{flower_id} }{$type_name}	= 1;
				}
			}
		}
	}

	# Did the user provide more that one attribute type?
	# If so, they must all match.

	my($flower_id);
	my($type_match_count);
	my(%wanted_flower_ids);

	for $flower_id (keys %candidate_flower_ids)
	{
		$type_match_count = 0;

		for my $type_name (@$type_names)
		{
			$type_match_count++ if ($candidate_flower_ids{$flower_id}{$type_name});
		}

		$wanted_flower_ids{$flower_id} = 1 if ($type_name_count == $type_match_count);
	}

	return \%wanted_flower_ids;

} # End of parse_search_attributes.

# -----------------------------------------------

sub parse_search_text
{
	my($self, $search_text)	= @_;
	$search_text			= uc $search_text;
	$search_text			=~ s/\s{2,}/ /g;
	my($search_status)		=
	{
		error_message	=> '',
		search_text		=> $search_text,
		text_is_clean	=> true,
		text_provided	=> true,
	};

	# Test input and return structured result.

	if ($search_text eq '')
	{
		$$search_status{text_provided} = false;
	}
	elsif ($search_text =~ /^[-A-Z0-9. ']+$/) # Use another ' to reset the UltraEdit syntax hiliter.
	{
	}
	elsif ($search_text =~ /^(HEIGHT|WIDTH)\s*([<=>])\s*([0-9]{0,3}(?:[.][0-9]{0,2})?)\s*(CM|M)$/)
	{
		# o The first word must be HEIGHT or WIDTH.
		# o Only 1 of the set [<=>] can appear.
		# o The last word must be CM or M.

		$$search_status{direction}	= $1;
		$$search_status{operator}	= $2;
		$$search_status{size}		= $3;
		$$search_status{unit}		= lc $4;

		$self -> logger -> debug("Captured '$$search_status{direction}' & '$$search_status{operator}' & '$$search_status{size}' & '$$search_status{unit}'");

		if ($$search_status{size} == 0)
		{
			$$search_status{size} = 1;
			$$search_status{unit} = 'm';
		}

		if ( ($$search_status{unit} eq 'cm') && ($$search_status{size} >= 100) )
		{
			$$search_status{size} /= 100;
		}
	}
	else
	{
		$$search_status{error_message}	= 'Unknown chars in text. Check Search FAQ for help with dimensions';
		$$search_status{text_is_clean}	= false;
	}

	return $search_status;

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
		$$record{hxw}			= $self -> clean_up_height_width($$flower{height}, $$flower{width});
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
	my($self, $attributes_table, $attribute_types_table, $constants_table, $search_attributes, $search_text) = @_;
	my($search_status) = $self -> parse_search_text($search_text);

	if ($$search_status{text_is_clean} -> isFalse)
	{
		return ([], $$search_status{text_is_clean});
	}

	my(@type_names)			= keys %$search_attributes;
	my($type_name_count)	= scalar @type_names;
	my($attribute_provided)	= ($type_name_count > 0) ? 1 : 0;
	my($wanted_flower_ids)	= $self -> parse_search_attributes($attribute_types_table, $attributes_table, $search_attributes, \@type_names, $type_name_count);
	my($flowers)			= $self -> read_flowers_table;
	my($result_set)			= [];

	my($attribute_match);
	my($flower_id);
	my($item);
	my($match);
	my($pig_latin);
	my($text_match);

	for my $flower (@$flowers)
	{
		$flower_id			= $$flower{id};
		$attribute_match	= $$wanted_flower_ids{$flower_id} || 0;
		$text_match			= $$search_status{text_provided} && ( (uc($$flower{aliases}) =~ /$$search_status{search_text}/)
								|| (uc($$flower{common_name}) =~ /$$search_status{search_text}/)
								|| (uc($$flower{scientific_name}) =~ /$$search_status{search_text}/) );

		if ($attribute_provided)
		{
			$match = $$search_status{text_provided} ? $attribute_match && $text_match : $attribute_match;
		}
		else
		{
			$match = $$search_status{text_provided} ? $text_match : 0;
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
				hxw				=> $self -> clean_up_height_width($$flower{height}, $$flower{width}),
				height			=> $$flower{height},
				pig_latin		=> $pig_latin,
				thumbnail_url	=> "$$constants_table{homepage_url}$$constants_table{image_url}/$pig_latin.0.jpg",
				width			=> $$flower{width},
			};

			push @$result_set, $item;
		}
	}

	$self -> logger -> info("Match count: @{[$#$result_set + 1]}");

	return ([sort{$$a{common_name} cmp $$b{common_name} } @$result_set], $search_status);

} # End of search.

# --------------------------------------------------

1;
