package WWW::Garden::Design::Database;

use boolean;
use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Dumper::Concise; # For Dumper().

use DBI;

use File::Slurper qw/read_dir/;

use FindBin;

use Lingua::EN::Inflect qw/inflect PL_N/; # PL_N: plural of a singular noun.

use Mojo::Pg;

use Moo;

use Text::CSV::Encoded;

use Time::HiRes qw/gettimeofday tv_interval/;

use Types::Standard qw/Object HashRef/;

use Unicode::Collate;

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

has mojo_pg =>
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

	$self -> mojo_pg(Mojo::Pg -> new("postgres://$$config{username}:$$config{password}\@localhost/flowers") -> db);
	$self -> constants($self -> read_constants_table); # Warning. Empty at start of import.

}	# End of BUILD.

# --------------------------------------------------

sub add_flower
{
	my($self) = @_;

	return '';

} # End of add_flower.

# -----------------------------------------------
# This version of build_property_menu() includes properties with and without gardens.

sub build_full_property_menu
{
	my($self, $properties, $id, $default_id) = @_;
	my($html)		= "<select id = '$id' name = '$id'>";
	my($last_name)	= '';

	my($name);
	my($selected);

	for my $property (sort{$$a{name} cmp $$b{name} } @$properties)
	{
		$name = $$property{name};

		if ($default_id > 0)
		{
			# Set given id as selected.

			$default_id	= 0;
			$last_name	= $name;
			$selected	= 'selected';
		}
		elsif ($last_name eq '')
		{
			# Set first id as selected if no id given.

			$last_name	= $name;
			$selected	= 'selected';
		}
		else
		{
			$selected = ''; # Reset it.
		}

		$html		.= "<option $selected value = '$$property{id}'>$name</option>";
		$selected	= '';
	}

	$html .= '</select>';

	return $html;

} # End of build_full_property_menu.

# -----------------------------------------------

sub build_garden_menu
{
	my($self, $property_gardens, $controller, $id) = @_;
	my($html)			= "<select id = '$id' name = '$id'>";
	my($last_name)		= '';
	my($property_id)	= $controller -> session('current_property_id');

	my($selected);

	for my $garden (@$property_gardens)
	{
		# This test assumes that within a property, all garden names are unique.

		next if ($property_id ne $$garden{property_id});

		if ($last_name eq '')
		{
			# Set this on the 1st menu item.

			$selected = 'selected';
		}

		$last_name	= $$garden{name};
		$html		.= "<option $selected value = '$$garden{id}'>$last_name</option>";
		$selected	= '';
	}

	$html .= '</select>';

	return $html;

} # End of build_garden_menu.

# -----------------------------------------------

sub build_object_menu
{
	my($self, $objects, $controller) = @_;
	my($html)		= "<div class = 'object_toolbar'>"
						. "<select id = 'object_menu'>";
	my($last_name)  = '';

	my($selected);

	for my $object (@$objects)
	{
		if ($last_name eq '')
		{
			# Set this on the 1st menu item.

			$selected = 'selected';
		}

		next if ($last_name eq $$object{name});

		$last_name	= $$object{name};
		$html		.= "<option $selected value = '$$object{id}'>$last_name</option>";
		$selected	= '';
	}

	$html .= "</select>\n</div>\n";

	return $html;

} # End of build_object_menu.

# -----------------------------------------------
# This version of full_build_property_menu() only includes properties with gardens.

sub build_property_menu
{
	my($self, $property_gardens, $controller, $id) = @_;
	my($html)		= "<select id = '$id' name = '$id'>";
	my($last_name)	= '';

	my($selected);

	for my $garden (@$property_gardens)
	{
		if ($last_name eq '')
		{
			# Set this on the 1st menu item.

			$selected = 'selected';

			# current_property_id is used in build_garden_menu().

			$controller -> session(current_property_id => $$garden{property_id});
		}

		next if ($last_name eq $$garden{property_name});

		$last_name	= $$garden{property_name};
		$html		.= "<option $selected value = '$$garden{property_id}'>$last_name</option>";
		$selected	= '';
	}

	$html .= '</select>';

	return $html;

} # End of build_property_menu.

# --------------------------------------------------

sub clean_up_icon_name
{
	my($self, $name)	= @_;
	my($file_name)		= $name =~ s/\s/./gr;

	return $file_name;

} # End of clean_up_icon_name.

# -----------------------------------------------

sub crosscheck
{
	my($self)	= @_;
	my($path)	= "$FindBin::Bin/../data/constants.csv";
	my($csv)	= Text::CSV::Encoded -> new
	({
		allow_whitespace => 1,
		encoding_in      => 'utf-8',
	});

	open(my $io, '<', $path) || die "Can't open($path): $!\n";

	$csv -> column_names($csv -> getline($io) );

	my(%constants);

	my($row) = 0;

	for my $item (@{$csv -> getline_hr_all($io) })
	{
		$row++;

		# Column names are in alphabetical order.

		for my $column (qw/name value/)
		{
			if (! defined $$item{$column})
			{
				print "File: $path. Row: $row. Column $column undefined. \n";
			}
		}

		$constants{$$item{name} } = $$item{value};
	}

	close $io;

	my($homepage_dir)	= $constants{homepage_dir};
	my($homepage_url)	= $constants{homepage_url};
	my($image_dir)		= $constants{image_dir};
	my($image_path)		= "$homepage_dir$image_dir";
	my($flowers)		= $self -> read_flowers_table;

	# Read in the actual file names.

	my(%file_list);

	my(@entries)						= read_dir $image_path;
	@entries							= sort grep{! -d "$image_path/$_"} @entries; # Can't call sort directly on output of read_dir!
	$file_list{file_names}				= [@entries];
	@{$file_list{name_hash} }{@entries}	= (1) x @entries;

	# Check that the files which ought to be there, are.

	my($count);
	my($common_name);
	my($file_name);
	my($image);
	my($pig_latin);
	my(%real_name);
	my($scientific_name);

	for my $flower (@$flowers)
	{
		$common_name			= $$flower{common_name};
		$scientific_name		= $$flower{scientific_name};
		$pig_latin				= $self -> scientific_name2pig_latin($flowers, $scientific_name, $common_name);
		$file_name				= "$pig_latin.0.jpg";
		$real_name{$file_name}	= 1;

		if (! $file_list{name_hash}{$file_name})
		{
			print "Missing thumbnail: $file_name\n";
		}

		for $image (@{$$flower{images} })
		{
			$file_name				= $$image{file_name} =~ s/\Q$homepage_url$image_dir\/\E//r;
			$real_name{$file_name}	= 1;

			if (! $file_list{name_hash}{$file_name})
			{
				print "Missing image: $file_name\n";
			}
		}
	}

	# Check for any unexpected files, .i.e present in the directory but not in images.csv.

	for my $file_name (@{$file_list{file_names} })
	{
		if (! $real_name{$file_name})
		{
				print "Unexpected image: $file_name\n";
		}
	}

	# Return 0 for OK and 1 for error.

	return 0;

} # End of crosscheck.

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

# -----------------------------------------------
# Return a list.

sub get_autocomplete_flower_list
{
	my($self, $key)	= @_;
	$key			=~ s/\'/\'\'/g; # Since we're using Pg.
	my($sql)		= "select distinct concat(scientific_name, '/', common_name) from flowers "
						. "where upper(scientific_name) like '%$key%' "
						. "or upper(common_name) like '%$key%' "
						. "or upper(aliases) like '%$key%'";

	return [$self -> mojo_pg -> query($sql) -> each];

} # End of get_autocomplete_flower_list.

# -----------------------------------------------
# Return a list.

sub get_autocomplete_object_list
{
	my($self, $key)	= @_;
	$key			=~ s/\'/\'\'/g; # Since we're using Pg.

	return [$self -> mojo_pg -> query("select distinct name from objects where upper(name) like '%$key%'") -> each];

} # End of get_autocomplete_object_list.

# -----------------------------------------------
# Return the shortest item in the list.

sub get_autocomplete_item
{
	my($self, $context, $type, $key) = @_;
	$key =~ s/\'/\'\'/g; # Since we're using Pg.

	my(@result);
	my($sql);

	for my $index (keys %$context)
	{
		my($search_column)	= $$context{$index}[0];
		my($table_name)		= $$context{$index}[1];

		# $search_column is a special case. See AutoComplete.pm and get_autocomplete_flower_list() above.

		next if ($search_column eq '*');

		# If we're not searching then we're processing the Add screen.
		# In that case, we're only interested in one $index at a time.

		if ( ($type ne 'search') && ($index ne $type) )
		{
			next;
		}

		$sql = "select distinct $search_column from $table_name where upper($search_column) like '%$key%'";

		push @result, ${$self -> mojo_pg -> query($sql) -> hashes -> each}{$search_column};
	}

	my($min_length) = 99; # Arbitrary.

	my($min_value);

	for (@result)
	{
		if (length($_) < $min_length)
		{
			$min_length	= length($_);
			$min_value	= $_;
		}
	}

	if ($min_value)
	{
		$self -> logger -> info("Return <$min_value>");

		return [$min_value];
	}
	else
	{
		return [];
	}

} # End of get_autocomplete_item.

# -----------------------------------------------

sub format_raw_message
{
	my($self, $result)	= @_;
	my($class)			= ($$result{type} eq 'Success') ? 'success' : 'error';
	$$result{cooked}	= "<span class = 'centered $class'>$$result{type}</span>: $$result{raw}";

	return $result;

} # End of format_raw_message.

# -----------------------------------------------
# Return a list.

sub get_autocomplete_list
{
	my($self, $context, $type, $key) = @_;
	$key =~ s/\'/\'\'/g; # Since we're using Pg.

	my(@list);
	my(@result);
	my($sql, %seen);

	for my $index (keys %$context)
	{
		my($search_column)	= $$context{$index}[0];
		my($table_name)		= $$context{$index}[1];

		# $search_column is a special case. See AutoComplete.pm and get_autocomplete_flower_list() above.

		next if ($search_column eq '*');

		# If we're not searching then we're processing the Add screen.
		# In that case, we're only interested in one $index at a time.

		if ( ($type ne 'search') && ($index ne $type) )
		{
			next;
		}

		# Using 'select distinct ...' did not weed out duplicates.

		$sql	= "select $search_column from $table_name where upper($search_column) like '%$key%'";
		@list	= map{$$_[0]} $self -> mojo_pg -> query($sql) -> arrays -> each;

		push @result, grep{! $seen{$_} } @list;

		$seen{$_} = 1 for @list;
	}

	return [@result];

} # End of get_autocomplete_list.

# --------------------------------------------------

sub get_flower_by_both_names
{
	my($self, $key)	= @_;
	my($constants)	= $self -> constants;
	$key			=~ s/\'/\'\'/g; # Since we're using Pg.
	$key			= uc $key;
	my(@key)		= split('/', $key);
	my($sql)		= "select pig_latin from flowers where upper(scientific_name) like ? and upper(common_name) like ?";
	my(@result)		= $self -> mojo_pg -> query($sql, $key[0], $key[1]) -> hashes;
	my($pig_latin)	= $#result >= 0 ? "$$constants{homepage_url}$$constants{image_url}/$result[0].0.jpg" : '';

	return $pig_latin;

} # End of get_flower_by_both_names.

# --------------------------------------------------

sub get_flower_by_id
{
	my($self, $flower_id)		= @_;
	my($attribute_types_table)	= $self -> read_table('attribute_types');
	my($sql)					= "select * from flowers where id = $flower_id";
	my($query)					= $self -> mojo_pg -> query($sql);
	my($flower)					= $query -> hash;

	$query -> finish;

	my(%attribute_type);

	for (@$attribute_types_table)
	{
		$attribute_type{$$_{id} } = $_;
	}

	for my $table_name (qw/attributes flower_locations images notes urls/)
	{
		# Return an arrayref of hashrefs.

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

# --------------------------------------------------

sub get_object_by_name
{
	my($self, $key)	= @_;
	my($constants)	= $self -> constants;
	$key			=~ s/\'/\'\'/g; # Since we're using Pg.
	$key			= "\U%$key"; # \U => Convert to upper-case.
	my($sql)		= "select name from objects where upper(name) like ?";
	my(@result)		= $self -> mojo_pg -> query($sql, $key) -> hashes;
	my($icon_name)	= $self -> clean_up_icon_name($result[0]);
	$icon_name		= length($icon_name) > 0 ? "$$constants{homepage_url}$$constants{icon_url}/$icon_name.png" : '';

	return $icon_name;

} # End of get_object_by_name.

# -----------------------------------------------

sub insert_hashref
{
	my($self, $table_name, $hashref) = @_;

	return ${$self -> mojo_pg -> insert
	(
		$table_name, {map{($_ => $$hashref{$_})} keys %$hashref}, {returning => ['id']}
	) -> hash}{id};

} # End of insert_hashref.

# -----------------------------------------------

sub parse_attribute_checkboxes
{
	my($self, $defaults, $search_attributes)	= @_;

	$self -> logger -> debug('Database.parse_attribute_checkboxes()');

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

	return \%checkboxes;

} # End of parse_attribute_checkboxes.

# -----------------------------------------------

sub parse_search_attributes
{
	my($self, $defaults, $search_attributes) = @_;

	$self -> logger -> debug('Database.parse_search_attributes()');

	my($checkboxes)			= $self -> parse_attribute_checkboxes($defaults, $search_attributes);
	my(@type_names)			= keys %$checkboxes;
	my($type_name_count)	= scalar @type_names;

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

	return (true, \%candidate_flower_ids);

} # End of parse_search_attributes.

# -----------------------------------------------

sub parse_search_text
{
	my($self, $search_text)	= @_;

	$self -> logger -> debug("Database.parse_search_text($search_text)");

	my($request) =
	{
		error_message	=> '',
		height_provided	=> false,
		lc_search_text	=> 'See below',
		original_text	=> $search_text, # Save in original case for display to the user.
		search_text		=> 'See below',
		size_provided	=> false,
		text_is_clean	=> true,
		text_provided	=> true,
		width_provided	=> false,
	};

	# Test input and return structured result.

	if ($search_text eq '')
	{
		$$request{text_provided} = false;
	}
	elsif ($search_text =~ /^(h|height|w|width)\s*([<=>])\s*([0-9]{0,3}(?:[.][0-9]{0,2})?)\s*(cm|m)?$/i)
	{
		my($direction) = $1;

		$$request{direction}		= ($direction eq 'height') ? 'h' : ($direction eq 'width') ? 'w' : $direction;
		$$request{height_provided}	= true if ($$request{direction} eq 'h');
		$$request{operator}			= $2;
		$$request{size}				= $3 || 1;
		$$request{size_provided}	= true;
		$$request{unit}				= $4 || 'm';
		$$request{width_provided}	= true if ($$request{direction} eq 'w');

		if ($$request{unit} eq 'm')
		{
			$$request{size}	*= 100;
			$$request{unit}	= 'cm';
		}
	}
	elsif (length($search_text) > 100) # Arbitrary limit.
	{
		$$request{error_message}	= 'Search text suspiciously long. Check Search FAQ for help with sizes';
		$$request{text_is_clean}	= false;
	}

	$$request{search_text}		= $search_text;
	$$request{lc_search_text}	= lc $search_text;

	return $request;

} # End of parse_search_text.

# --------------------------------------------------

sub process_garden_submit
{
	my($self, $item) = @_;

	$self -> logger -> debug('Database.process_garden_submit(...)');

	my($action)			= $$item{action};
	my($id)				= $$item{id};
	my($name)			= $$item{name};
	my($result) 		= {garden_id => 0};
	my($table_name)		= 'gardens';
	my($gardens_table)	= $self -> read_table($table_name);
	my($fields)			=
	{
		description	=> $$item{description},
		name		=> $name,
		property_id	=> $$item{property_id},
		publish		=> $$item{publish},
	};

	my(%garden);

	if ($action eq 'save')
	{
		# It's a garden insert. Is the garden name on file?
		# AddGarden.pm checked that the user entered something!

		for (@$gardens_table)
		{
			$garden{uc $$_{name} } = $$_{id} if ($$_{property_id} == $$item{property_id});
		}

		if (exists($garden{uc $name}) )
		{
			$result = {raw => 'That garden name is on file for this property', type => 'Error'};
		}
		else
		{
			$id = $self -> mojo_pg -> insert
			(
				$table_name,
				$fields,
				{returning => 'id'}
			) -> hash -> {id};

			$self -> logger -> debug("Table: $table_name. Record id: $id. Action: $action. Garden: $name");

			$result = {garden_id => $id, raw => "Added garden: $name", type => 'Success'};
		}
	}
	elsif ($action eq 'update')
	{
		# Is the garden id on file? AddGarden.pm checked that the user entered something!

		for (@$gardens_table)
		{
			$garden{$$_{id} } = $$_{name};
		}

		if (exists($garden{$id}) )
		{
			# It's a garden update.

			$self -> mojo_pg -> update
			(
				$table_name,
				$fields,
				{id => $$item{id} }
			);

			$self -> logger -> debug("Table: $table_name. Record id: $id. Action: $action");

			$result = {garden_id => $$item{id}, raw => "Property: $name. Action: $action", type => 'Success'};
		}
		else
		{
			$result = {raw => 'Cannot update the database. That record was not found', type => 'Error'};
		}
	}
	elsif ($action eq 'delete')
	{
		# Is the garden id on file? AddGarden.pm checked that the user entered something!

		for (@$gardens_table)
		{
			$garden{$$_{id} } = $$_{name};
		}

		if (exists($garden{$id}) )
		{
			# It's a property delete. But does this property have any gardens?

			my($found)			= false;
			my($garden_table)	= $self -> read_table('gardens');

			for my $garden (@$gardens_table)
			{
				if ($$garden{property_id} == $$item{id})
				{
					$found = true;
				}
			}

			if ($found -> isTrue)
			{
				my($note) = "Not deleted because the property has gardens";

				$self -> logger -> debug("Table: $table_name. Record id: $id. $note");

				$result = {raw => "Property: $name. $note", type => 'Error'};
			}
			else
			{
				$self -> mojo_pg -> delete
				(
					$table_name,
					{id => $$item{id} }
				);

				$self -> logger -> debug("Table '$table_name'. Record id '$id' ${action}d.");

				$result = {raw => "Property: $name. Action: $action", type => 'Success'};
			}
		}
		else
		{
			$result = {raw => 'Cannot update the database. That record was not found', type => 'Error'};
		}
	}
	else
	{
		$result = {raw => "Unrecognized action: $action. Must be one of 'save', 'update' or 'delete'", type => 'Error'};
	}

	return
	{
		garden_table	=> $self -> read_gardens_table,
		message			=> $self -> format_raw_message($result),
	};

} # End of process_garden_submit.

# --------------------------------------------------

sub process_property_submit
{
	my($self, $item) = @_;

	$self -> logger -> debug('Database.process_property_submit(...)');

	my($action)				= $$item{action};
	my($id)					= $$item{id};
	my($name)				= $$item{name};
	my($table_name)			= 'properties';
	my($properties_table)	= $self -> read_table($table_name);
	my($result) 			= {property_id => 0};
	my($fields)				=
	{
		description	=> $$item{description},
		name		=> $name,
		publish		=> $$item{publish},
	};

	my(%property);

	if ($action eq 'save')
	{
		# It's a property insert. Is the property name on file?
		# AddProperty.pm checked that the user entered something!

		for (@$properties_table)
		{
			$property{uc $$_{name} } = $$_{id};
		}

		if (exists($property{uc $name}) )
		{
			$result = {raw => 'That property name is on file', type => 'Error'};
		}
		else
		{
			$id = $self -> mojo_pg -> insert
			(
				$table_name,
				$fields,
				{returning => 'id'}
			) -> hash -> {id};

			$self -> logger -> debug("Table: $table_name. Record id: $id. Action: $action. Property: $name");

			$result = {property_id => $id, raw => "Added property: $name", type => 'Success'};
		}
	}
	elsif ($action eq 'update')
	{
		# Is the property id on file? AddProperty.pm checked that the user entered something!

		for (@$properties_table)
		{
			$property{$$_{id} } = $$_{name};
		}

		if (exists($property{$id}) )
		{
			# It's a property update.

			$self -> mojo_pg -> update
			(
				$table_name,
				$fields,
				{id => $$item{id} }
			);

			$self -> logger -> debug("Table: $table_name. Record id '$id'. Action: $action");

			$result = {property_id => $$item{id}, raw => "Property: $name. Action: $action", type => 'Success'};
		}
		else
		{
			$result = {raw => 'Cannot update the database. That record was not found', type => 'Error'};
		}
	}
	elsif ($action eq 'delete')
	{
		# Is the property id on file? AddProperty.pm checked that the user entered something!

		for (@$properties_table)
		{
			$property{$$_{id} } = $$_{name};
		}

		if (exists($property{$id}) )
		{
			# It's a property delete. But does this property have any gardens?

			my($found)			= false;
			my($garden_table)	= $self -> read_table('gardens');

			for my $garden (@$garden_table)
			{
				if ($$garden{property_id} == $$item{id})
				{
					$found = true;
				}
			}

			if ($found -> isTrue)
			{
				my($note) = "Not deleted because the property has gardens";

				$self -> logger -> debug("Table: $table_name. Record id: $id. $note");

				$result = {raw => "Property: $name. $note", type => 'Error'};
			}
			else
			{
				$self -> mojo_pg -> delete
				(
					$table_name,
					{id => $$item{id} }
				);

				$self -> logger -> debug("Table: $table_name. Record id: $id. Action: $action");

				$result = {raw => "Property: $name. Action $action", type => 'Success'};
			}
		}
		else
		{
			$result = {raw => 'Cannot update the database. That record was not found', type => 'Error'};
		}
	}
	else
	{
		$result = {raw => "Unrecognized action: $action. Must be one of 'save', 'update' or 'delete'", type => 'Error'};
	}

	return
	{
		full_property_table	=> $self -> read_properties_table,
		message				=> $self -> format_raw_message($result),
	};

} # End of process_property_submit.

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

	# Return an arrayref of hashrefs.

	return [$self -> mojo_pg -> query("select * from $table_name where flower_id = $flower_id") -> hashes -> each];

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
		$record	= {};

		for my $key (keys %$flower)
		{
			$$record{$key} = $$flower{$key};
		}

		$pig_latin				= $$flower{pig_latin};
		$$record{hxw}			= $self -> format_height_width($$flower{height}, $$flower{width});
		$$record{thumbnail_url}	= "$$constants{homepage_url}$$constants{image_url}/$pig_latin.0.jpg";
		$$record{web_page_url}	= "$$constants{homepage_url}$$constants{flower_url}/$pig_latin.html";

		# Warning: Obviously this loop only works if $table_name never matches $key in the above loop.

		for my $table_name (qw/attributes flower_locations images notes urls/)
		{
			# Return an arrayref of hashrefs.

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

		# Fix the urls.

		for my $i (0 .. $#{$$record{images} })
		{
			$$record{images}[$i]{raw_name}	= $$record{images}[$i]{file_name};
			$$record{images}[$i]{file_name}	= "$$constants{homepage_url}$$constants{image_url}/$$record{images}[$i]{file_name}";
		}

		push @records, $record;
	}

	# Sort the flowers according to their scientific name.
	# Warning: This sort is overridden by JS in Datatables. See Base.pm.

	my($index) = 0;

	my($key, @keys);
	my(%records);

	for my $record (@records)
	{
		$index++;

		$key			= "$$record{scientific_name}:$index";
		$records{$key}	= $record;

		push @keys, $key;
	}

	@keys		= Unicode::Collate -> new -> sort(@keys);
	@records	= ();

	for $key (@keys)
	{
		push @records, $records{$key};
	}

	# Return an arrayref of hashrefs.

	return [@records];

} # End of read_flowers_table.

# --------------------------------------------------

sub read_garden_dependencies
{
	my($self, $table_name, $garden_id) = @_;

	# Return an arrayref of hashrefs.

	return [$self -> mojo_pg -> query("select * from $table_name where garden_id = $garden_id") -> hashes -> each];

} # End of read_garden_dependencies.

# --------------------------------------------------

sub read_gardens_table
{
	my($self)				= @_;
	my($constants)			= $self -> constants;
	my($garden_table)		= $self -> read_table('gardens'); # Avoid 'Deep Recursion'! Don't call read_gardens_table()!
	my($properties_table)	= $self -> read_table('properties');

	my($id);
	my($property_id);
	my($record, @records);

	my(%property);

	for (@$properties_table)
	{
		$property{$$_{id} } = $_;
	}

	for my $garden (@$garden_table)
	{
		$record	= {};

		for my $key (keys %$garden)
		{
			$$record{$key} = $$garden{$key};
		}


		for my $table_name (qw/flower_locations object_locations/)
		{
			$$record{$table_name} = $self -> read_garden_dependencies($table_name, $$record{id});
		}

		# Annotate the records with their properties.

		$$record{property_description}	= $property{$$record{property_id} }{description};
		$$record{property_name}			= $property{$$record{property_id} }{name};
		$$record{property_publish}		= $property{$$record{property_id} }{publish};

		push @records, $record;
	}

	# Return an arrayref of hashrefs.

	return [sort{$$a{property_name} cmp $$b{property_name} || $$a{name} cmp $$b{name} } @records];

} # End of read_gardens_table.

# --------------------------------------------------

sub read_object_dependencies
{
	my($self, $table_name, $object_id) = @_;

	# Return an arrayref of hashrefs.

	return [$self -> mojo_pg -> query("select * from $table_name where object_id = $object_id") -> hashes -> each];

} # End of read_object_dependencies.

# --------------------------------------------------

sub read_objects_table
{
	my($self)		= @_;
	my($constants)	= $self -> constants;

	my($record, @records);

	for my $object (@{$self -> read_table('objects')})
	{
		$record	= {};

		for my $key (keys %$object)
		{
			$$record{$key} = $$object{$key};
		}

		$$record{icon_dir}	= "$$constants{homepage_dir}$$constants{icon_dir}";
		$$record{icon_file}	= $self -> clean_up_icon_name($$object{name});
		$$record{icon_url}	= "$$constants{homepage_url}$$constants{icon_url}/$$record{icon_file}.png";

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

sub read_properties_table
{
	my($self)		= @_;
	my($constants)	= $self -> constants;

	# Return an arrayref of hashrefs.

	return [sort{$$a{name} cmp $$b{name} } @{$self -> read_table('properties')}];

} # End of read_properties_table.

# --------------------------------------------------

sub read_table
{
	my($self, $table_name) = @_;

	# Return an arrayref of hashrefs.

	return [$self -> mojo_pg -> query("select * from $table_name") -> hashes -> each];

} # End of read_table.

# --------------------------------------------------

sub scientific_name2pig_latin
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

} # End of scientific_name2pig_latin.

# --------------------------------------------------

sub search
{
	my($self, $defaults, $constants_table, $search_attributes, $search_text) = @_;

	$self -> logger -> debug('Database.search()');

	my($request) = $self -> parse_search_text($self -> trim($search_text) );

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
				height			=> $$flower{height},
				hxw				=> $self -> format_height_width($$flower{height}, $$flower{width}),
				id				=> $flower_id,
				pig_latin		=> $pig_latin,
				publish			=> $$flower{publish},
				scientific_name	=> $$flower{scientific_name},
				thumbnail_url	=> "$$constants_table{homepage_url}$$constants_table{image_url}/$pig_latin.0.jpg",
				width			=> $$flower{width},
			};

			push @$result_set, $item;
		}
	}

	$$request{time_taken} = tv_interval($start_time);

	$self -> logger -> info("Match count: @{[$#$result_set + 1]}");

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

# -----------------------------------------------

sub upper_name2id_map
{
	my($self, $table_name)	= @_;
	my(%result)				= map{($$_{name} => $$_{id})} $self -> mojo_pg -> query("select upper(name) as name, id from $table_name") -> hashes -> each;

	return {%result};

} # End of upper_name2id_map.

# --------------------------------------------------

1;

=pod

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/WWW-Garden-Design>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=WWW::Garden::Design>.

=head1 Author

L<WWW::Garden::Design> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2014.

My homepage: L<https://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2013, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
