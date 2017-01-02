package WWW::Garden::Design::Database;

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

our $VERSION = '1.00';

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
	my($self, $attributes_table, $attribute_types_table, $constants_table, $search_attributes, $search_key)	= @_;
	my(@search_type_names)	= keys %$search_attributes;
	my($flowers)			= $self -> read_flowers_table;
	$search_key				= uc $search_key;
	my($result_set)			= [];

	$self -> logger -> debug('Database.search() parameters:');
	$self -> logger -> debug('constants_table: ' . Dumper($constants_table) );
	$self -> logger -> debug('search_key: ' . Dumper($search_key) );
	$self -> logger -> debug('search_attributes: ' . Dumper($search_attributes) );

	my($item);
	my($pig_latin);

	# Did the user provide attributes?

	for my $search_type_name (@search_type_names)
	{
		my($attribute_type_id) = 0;

		my(@flower_ids);

		for my $attribute_type (@$attribute_types_table)
		{
			$self -> logger -> debug("Compare $$attribute_type{name} eq $search_type_name.");

			if ($$attribute_type{name} eq $search_type_name)
			{
				$attribute_type_id = $$attribute_type{id};
			}
		}

		if ($attribute_type_id > 0)
		{
			for my $attribute (@$attributes_table)
			{
				if ( ($$attribute{attribute_type_id} == $attribute_type_id) && ($$attribute{range} =~ /$$search_attributes{$search_type_name}/) )
				{
					push @flower_ids, $$attribute{flower_id};
				}
			}

			$self -> logger -> debug('Found flower_ids: ' . join(', ', @flower_ids) . '.');
		}

	}

	# Did the user provide text?

	if ($search_key ne '')
	{
		for my $flower (@$flowers)
		{
			if ( (uc($$flower{aliases}) =~ /$search_key/)
				|| (uc($$flower{common_name}) =~ /$search_key/)
				|| (uc($$flower{scientific_name}) =~ /$search_key/) )
			{
				$pig_latin	= $$flower{pig_latin};
				$item		=
				{
					aliases			=> $$flower{aliases},
					attributes		=> $$flower{attributes},
					common_name		=> $$flower{common_name},
					id				=> $$flower{id},
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
	}

	$self -> logger -> info("Match count: @{[$#$result_set + 1]}");

	return [sort{$$a{common_name} cmp $$b{common_name} } @$result_set];

} # End of search.

# --------------------------------------------------

1;
