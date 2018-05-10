package WWW::Garden::Design::Database;

use Moo::Role;

use boolean;
use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Dumper::Concise; # For Dumper().

use File::Slurper qw/read_dir/;

use FindBin;

use Imager;
use Imager::Fill;

use Lingua::EN::Inflect qw/inflect PL_N/; # PL_N: plural of a singular noun.

use Text::CSV::Encoded;

use Time::HiRes qw/gettimeofday tv_interval/;

use Types::Standard qw/Any Object HashRef/;

use Unicode::Collate;

has constants =>
(
	default		=> sub{return {} },
	is			=> 'rw',
	isa			=> HashRef,
	required	=> 0,
);

has db =>
(
	is			=> 'rw',
	isa			=> Any,
	required	=> 0,
);

has logger =>
(
	is			=> 'rw',
	isa			=> Object,
	required	=> 0,
);

has title_font =>
(
	default		=> sub{return ''},
	is			=> 'rw',
	isa			=> Any,
	required	=> 0,
);

our $VERSION = '0.96';

# --------------------------------------------------

sub add_flower
{
	my($self) = @_;

	return '';

} # End of add_flower.

# -----------------------------------------------

sub build_garden_menu
{
	my($self, $controller, $gardens_table, $jquery_id) = @_;
	my($found)			= false;
	my($html)			= "<select id = '$jquery_id' name = '$jquery_id'>";
	my($property_id)	= $controller -> session('current_property_id');

	my($selected);

	for my $garden (@$gardens_table)
	{
		# This test assumes that within a property, all garden names are unique.

		next if ($property_id ne $$garden{property_id});

		if ($found -> isFalse)
		{
			# Set this on the 1st menu item.

			$found		= true;
			$selected	= 'selected';
		}

		$html		.= "<option $selected value = '$$garden{id}'>$$garden{name}</option>";
		$selected	= '';
	}

	$html .= '</select>';

	return $html;

} # End of build_garden_menu.

# -----------------------------------------------

sub build_gardens_property_menu
{
	my($self, $controller, $gardens_table, $jquery_id, $default_id) = @_;

	my(%property_name);

	for my $garden (@$gardens_table)
	{
		$property_name{$$garden{property_name} } = $$garden{property_id};
	}

	my($found)			= false;
	my($html)			= "<select id = '$jquery_id' name = '$jquery_id'>";
	my($selected)		= '';

	for my $property_name (sort keys %property_name)
	{
		my($property_id) = $property_name{$property_name};

		if 	($found -> isFalse &&
				(
					($default_id == 0) || ($default_id == $property_id)
				)
			)
		{
			# Set this on the 1st menu item or the one desired.

			$found		= true;
			$selected	= ' selected';

			# current_property_id is used in build_garden_menu().

			$controller -> session(current_property_id => $property_id);
		}

		$html		.= "<option$selected value = '$property_id'>$property_name</option>";
		$selected	= '';
	}

	$html .= '</select>';

	return $html;

} # End of build_gardens_property_menu.

# -----------------------------------------------

sub build_feature_menu
{
	my($self, $features, $default_id) = @_;
	my($found)	= false;
	my($html)	= "<div class = 'feature_toolbar'>"
					. "<select id = 'feature_menu'>";

	my($selected);

	for my $feature (@$features)
	{
		my($feature_id) = $$feature{id};

		if 	($found -> isFalse &&
				(
					($default_id == 0) || ($default_id == $feature_id)
				)
			)
		{
			# Set this on the 1st menu item or the one desired.

			$found		= true;
			$selected	= ' selected';
		}

		$html		.= "<option$selected value = '$feature_id'>$$feature{name}</option>";
		$selected	= '';
	}

	$html .= "</select>\n</div>\n";

	return $html;

} # End of build_feature_menu.

# -----------------------------------------------

sub build_properties_property_menu
{
	my($self, $properties, $jquery_id, $default_id) = @_;
	my($html)		= "<select id = '$jquery_id' name = '$jquery_id'>";
	my($last_name)	= '';

	my($id);
	my($name);
	my($selected);

	for my $property (sort{$$a{name} cmp $$b{name} } @$properties)
	{
		# $id can never be 0, but $default_id can be.

		$id		= $$property{id};
		$name	= $$property{name};

		if ($default_id == $id)
		{
			# Set given id as selected.

			$default_id	= 0;
			$last_name	= $name;
			$selected	= ' selected';
		}
		elsif ($default_id > 0)
		{
			$selected = '';
		}
		elsif ($last_name eq '')
		{
			# Set first id as selected if no id given.

			$last_name	= $name;
			$selected	= ' selected';
		}
		else
		{
			$selected = '';
		}

		$html		.= "<option$selected value = '$$property{id}'>$name</option>";
		$selected	= '';
	}

	$html .= '</select>';

	return $html;

} # End of build_properties_property_menu.

# --------------------------------------------------

sub clean_up_icon_name
{
	my($self, $name)	= @_;
	my($file_name)		= $name =~ s/\s/./gr;

	return $file_name;

} # End of clean_up_icon_name.

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
# Using "<span class = 'centered $class'>$$result{type}</span>" only centers it within the span 'garden_result_div'.

sub format_raw_message
{
	my($self, $result)	= @_;
	my($class)			= ($$result{type} eq 'Success') ? 'success' : 'error';
	$$result{cooked}	= "<h2 class = 'centered'><span class = '$class'>$$result{type}</span>: $$result{raw}</h2>";

	return $result;

} # End of format_raw_message.

# -----------------------------------------------

sub format_string
{
	my($self, $cell_width, $cell_height, $image, $string) = @_;
	my(@words)			= split(/\s+/, $string);
	my($step_count)		= $#words + 2;
	my($vertical_step)	= int($cell_height / $step_count);
	my($y)				= 0;
	my(%vowel)			= (a => 1, e => 1, i => 1, o => 1, u => 1);

	my($after_word);
	my($finished);
	my($index);
	my(@letters);
	my($word);

	for my $step (0 .. $#words)
	{
		$y			+= $vertical_step;
		$word		= $words[$step];
		@letters	= split(//, $word);
		$index		= $#letters;
		$finished	= $index <= 7; # Don't zap the 'a' in the word 'a'.

		while (! $finished)
		{
			if ($vowel{$letters[$index]})
			{
				splice(@letters, $index, 1);
			}

			$index--;

			$finished = 1 if ($#letters <= 7);
		}

		$after_word = join('', @letters);

		$image -> align_string
		(
			aa		=> 1,
			font	=> $self -> title_font,
			halign	=> 'center',
			string	=> $after_word,
			x		=> int($cell_width / 2),
			y		=> $y,
		);
	}

} # End of format_string.

# -----------------------------------------------

sub generate_tile
{
	my($self, $constants, $feature) = @_;
	my($color)		= Imager::Color -> new($$feature{hex_color});
	my($fill)		= Imager::Fill -> new(fg => $color, hatch => $$constants{tile_hatch_pattern});
	my($id)			= $$feature{id};
	my($image)		= Imager -> new(xsize => $$constants{cell_width}, ysize => $$constants{cell_height});
	my($name)		= $$feature{name};
	my($file_name)	= $self -> clean_up_icon_name($name);

	$image -> box(fill => $fill);
	$self -> format_string($$constants{cell_width}, $$constants{cell_height}, $image, $name);

	$image -> write(file => "$$feature{icon_dir}/$file_name.png");

	return [$name, $file_name];

} # End of generate_tile.

# --------------------------------------------------

sub get_feature_by_name
{
	my($self, $key)	= @_;
	my($constants)	= $self -> constants;
	$key			=~ s/\'/\'\'/g; # Since we're using Pg.
	$key			= "\U%$key"; # \U => Convert to upper-case.
	my($sql)		= "select name from features where upper(name) like ?";
	my(@result)		= $self -> db -> query($sql, $key) -> hashes;
	my($icon_name)	= $self -> clean_up_icon_name($result[0]);
	$icon_name		= length($icon_name) > 0 ? "$$constants{homepage_url}$$constants{icon_url}/$icon_name.png" : '';

	return $icon_name;

} # End of get_feature_by_name.

# --------------------------------------------------

sub get_flower_by_both_names
{
	my($self, $key)	= @_;
	my($constants)	= $self -> constants;
	$key			=~ s/\'/\'\'/g; # Since we're using Pg.
	$key			= uc $key;
	my(@key)		= split('/', $key);
	my($sql)		= "select pig_latin from flowers where upper(scientific_name) like ? and upper(common_name) like ?";
	my(@result)		= $self -> db -> query($sql, $key[0], $key[1]) -> hashes;
	my($pig_latin)	= $#result >= 0 ? "$$constants{homepage_url}$$constants{image_url}/$result[0].0.jpg" : '';

	return $pig_latin;

} # End of get_flower_by_both_names.

# --------------------------------------------------

sub get_flower_by_id
{
	my($self, $flower_id)		= @_;
	my($attribute_types_table)	= $self -> read_table('attribute_types');
	my($sql)					= "select * from flowers where id = $flower_id";
	my($query)					= $self -> db -> query($sql);
	my($flower)					= $query -> hash; # Only 1 record can match, so no need to call finish().

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

# -----------------------------------------------

sub init_imager
{
	my($self)	= @_;
	my($config)	= $self -> config;

	$self -> constants($self -> read_constants_table); # Might be empty at the start of an import.

	my($constants)	= $self -> constants;
	my($font_file)	= $$constants{tile_font_file} || $$config{tile_font_file};
	my($font_size)	= $$constants{tile_font_size} || $$config{tile_font_size};

	$self -> title_font
	(
		Imager::Font -> new
		(
			color	=> Imager::Color -> new(0, 0, 0), # Black.
			file	=> $font_file,
			size	=> $font_size,
		) || die "Error. Can't define title font: " . Imager -> errstr
	);

} # End of init_imager;

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

sub process_feature
{
	my($self, $item) = @_;

	$self -> logger -> debug('Database.process_feature(...)');

	my($action)			= $$item{action};
	my($id)				= $$item{id};
	my($name)			= $$item{name};
	my($table_name)		= 'features';
	my($features_table)	= $self -> read_table($table_name);
	my($result) 		= {feature_id => 0};
	my($fields)			=
	{
		hex_color	=> $$item{color_chosen},
		name		=> $name,
		publish		=> $$item{publish},
	};

#	color_chosen:	color_chosen,
#	color_code:		$('#color_code').val(),
#	color_name:		$('#color_name').val(),
#	id:				features_current_feature_id,
#	name:			feature_name,
#	publish:		$('#feature_publish').prop('checked') ? 'Yes' : 'No'

	my(%feature);

	if ($action eq 'add')
	{
		# It's a feature insert. Is the feature name on file?
		# Feature.pm checked that the user entered something!

		for (@$features_table)
		{
			$feature{uc $$_{name} } = $$_{id};
		}

		if (exists($feature{uc $name}) )
		{
			$result = {raw => 'Feature: $name. That feature name is on file', type => 'Error'};
		}
		else
		{
			$id = $self -> db -> insert
			(
				$table_name,
				$fields,
				{returning => 'id'}
			) -> hash -> {id};

			$self -> logger -> debug("Table: $table_name. Record id: $id. Feature: $name. Action: $action");

			$result = {feature_id => $id, raw => "Added feature: $name", type => 'Success'};
		}
	}
	elsif ($action eq 'delete')
	{
		# Is the feature id on file? Feature.pm checked that the user entered something!

		for (@$features_table)
		{
			$feature{$$_{id} } = $$_{name};
		}

		if (exists($feature{$id}) )
		{
			# It's a feature delete. But is this feature used in any gardens?

			my($found)			= false;

=pod

#TODO
			my($garden_table)	= $self -> read_table('gardens');

			for my $garden (@$garden_table)
			{
				if ($$garden{property_id} == $$item{id})
				{
					$found = true;
				}
			}

=cut

			if ($found -> isTrue)
			{
				my($note) = "Feature not deleted because it is used in some gardens";

				$self -> logger -> debug("Table: $table_name. Record id: $id. Feature: $name. $note");

				$result = {raw => "Feature: $name. $note", type => 'Error'};
			}
			else
			{
				$self -> db -> delete
				(
					$table_name,
					{id => $$item{id} }
				);

				$self -> logger -> debug("Table: $table_name. Record id: $id. Feature: $name. Action: $action");

				$result = {raw => "Feature: $name. Action $action", type => 'Success'};
			}
		}
		else
		{
			$result = {raw => "Feature: $name. Cannot update the database. That record was not found", type => 'Error'};
		}
	}
	elsif ($action eq 'update')
	{
		# Is the feature id on file? Feature.pm checked that the user entered something!

		for (@$features_table)
		{
			$feature{$$_{id} } = $$_{name};
		}

		if (exists($feature{$id}) )
		{
			# It's a feature update.

			$self -> db -> update
			(
				$table_name,
				$fields,
				{id => $$item{id} }
			);

			$self -> logger -> debug("Table: $table_name. Record id '$id'. Feature: $name. Action: $action");

			$result = {feature_id => $$item{id}, raw => "Feature: $name. Action: $action", type => 'Success'};
		}
		else
		{
			$result = {raw => "Feature: $name. Cannot update the database. That record was not found", type => 'Error'};
		}
	}
	else
	{
		$result = {raw => "Feature: $name. Unrecognized action: $action. Must be one of 'add', 'update' or 'delete'", type => 'Error'};
	}

	$features_table = $self -> read_features_table;

	return
	{
		message			=> $self -> format_raw_message($result),
		feature_menu	=> $self -> build_feature_menu($features_table, $$result{feature_id}),
		features_table	=> $features_table,
	};

} # End of process_feature.

# --------------------------------------------------

sub process_garden
{
	my($self, $controller, $item) = @_;

	$self -> logger -> debug('Database.process_garden(...)');

	my($action)			= $$item{action};
	my($garden_name)	= $$item{name};
	my($id)				= $$item{id};
	my($property_name)	= $$item{property_name};
	my($result) 		= {garden_id => 0};
	my($table_name)		= 'gardens';
	my($gardens_table)	= $self -> read_table($table_name);
	my($fields)			=
	{
		description	=> $$item{description},
		name		=> $garden_name,
		property_id	=> $$item{property_id},
		publish		=> $$item{publish},
	};

	my(%garden);

	if ($action eq 'add')
	{
		# It's a garden insert. Is the garden name on file?
		# Garden.pm checked that the user entered something!

		for (@$gardens_table)
		{
			$garden{uc $$_{name} } = $$_{id} if ($$_{property_id} == $$item{property_id});
		}

		if (exists($garden{uc $garden_name}) )
		{
			$result = {raw => "Property: $property_name. Garden: $garden_name. That garden name is on file", type => 'Error'};
		}
		else
		{
			$id = $self -> db -> insert
			(
				$table_name,
				$fields,
				{returning => 'id'}
			) -> hash -> {id};

			$self -> logger -> debug("Table: $table_name. Record id: $id. Action: $action. Property: $property_name. Garden: $garden_name");

			$result = {garden_id => $id, raw => "Property: $property_name. Added garden: $garden_name", type => 'Success'};
		}
	}
	elsif ($action eq 'delete')
	{
		# Is the garden id on file? Garden.pm checked that the user entered something!

		for (@$gardens_table)
		{
			$garden{$$_{id} } = $$_{name};
		}

		if (exists($garden{$id}) )
		{
			$self -> db -> delete
			(
				$table_name,
				{id => $$item{id} }
			);

			my($message) = "Property: $property_name. Garden: $garden_name. Action: $action";

			$self -> logger -> debug("Table '$table_name'. Record id '$id'. $message");

			$result = {raw => $message, type => 'Success'};
		}
		else
		{
			$result = {raw => "Property: $property_name. Garden: $garden_name. Cannot update the database. That record was not found", type => 'Error'};
		}
	}
	elsif ($action eq 'update')
	{
		# Is the garden id on file? Garden.pm checked that the user entered something!

		for (@$gardens_table)
		{
			$garden{$$_{id} } = $$_{name};
		}

		if (exists($garden{$id}) )
		{
			# It's a garden update.

			$self -> db -> update
			(
				$table_name,
				$fields,
				{id => $$item{id} }
			);

			$self -> logger -> debug("Table: $table_name. Record id: $id. Property: $property_name. Garden: $garden_name. Action: $action");

			$result = {garden_id => $$item{id}, raw => "Property: $property_name. Garden. $garden_name. Action: $action", type => 'Success'};
		}
		else
		{
			$result = {raw => "Property: $property_name. Garden: $garden_name. Cannot update the database. That record was not found", type => 'Error'};
		}
	}
	else
	{
		$result = {raw => "Property: $property_name. Garden: $garden_name. Unrecognized action: $action. Must be one of 'add', 'update' or 'delete'", type => 'Error'};
	}

	if ($$result{type} eq 'Error')
	{
		$self -> app -> log -> error($$result{raw});
	}

	$gardens_table = $self -> read_gardens_table;

	return
	{
		gardens_table	=> $gardens_table,
		message			=> $self -> format_raw_message($result),
		property_menu	=> $self -> build_gardens_property_menu($controller, $gardens_table, 'gardens_property_menu_1', $$item{property_id}),
	};

} # End of process_garden.

# --------------------------------------------------

sub process_property
{
	my($self, $item) = @_;

	$self -> logger -> debug('Database.process_property(...)');

	my($action)				= $$item{action};
	my($id)					= $$item{id};
	my($property_name)		= $$item{name};
	my($table_name)			= 'properties';
	my($properties_table)	= $self -> read_table($table_name);
	my($result) 			= {property_id => 0};
	my($fields)				=
	{
		description	=> $$item{description},
		name		=> $property_name,
		publish		=> $$item{publish},
	};

	my(%property);

	if ($action eq 'add')
	{
		# It's a property insert. Is the property name on file?
		# Property.pm checked that the user entered something!

		for (@$properties_table)
		{
			$property{uc $$_{name} } = $$_{id};
		}

		if (exists($property{uc $property_name}) )
		{
			$result = {raw => 'Property: $property_name. That property name is on file', type => 'Error'};
		}
		else
		{
			$id = $self -> db -> insert
			(
				$table_name,
				$fields,
				{returning => 'id'}
			) -> hash -> {id};

			$self -> logger -> debug("Table: $table_name. Record id: $id. Property: $property_name. Action: $action");

			$result = {property_id => $id, raw => "Added property: $property_name", type => 'Success'};
		}
	}
	elsif ($action eq 'delete')
	{
		# Is the property id on file? Property.pm checked that the user entered something!

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
				my($note) = "Property not deleted because it has gardens";

				$self -> logger -> debug("Table: $table_name. Record id: $id. Property: $property_name. $note");

				$result = {raw => "Property: $property_name. $note", type => 'Error'};
			}
			else
			{
				$self -> db -> delete
				(
					$table_name,
					{id => $$item{id} }
				);

				$self -> logger -> debug("Table: $table_name. Record id: $id. Property: $property_name. Action: $action");

				$result = {raw => "Property: $property_name. Action $action", type => 'Success'};
			}
		}
		else
		{
			$result = {raw => "Property: $property_name. Cannot update the database. That record was not found", type => 'Error'};
		}
	}
	elsif ($action eq 'update')
	{
		# Is the property id on file? Property.pm checked that the user entered something!

		for (@$properties_table)
		{
			$property{$$_{id} } = $$_{name};
		}

		if (exists($property{$id}) )
		{
			# It's a property update.

			$self -> db -> update
			(
				$table_name,
				$fields,
				{id => $$item{id} }
			);

			$self -> logger -> debug("Table: $table_name. Record id '$id'. Property: $property_name. Action: $action");

			$result = {property_id => $$item{id}, raw => "Property: $property_name. Action: $action", type => 'Success'};
		}
		else
		{
			$result = {raw => "Property: $property_name. Cannot update the database. That record was not found", type => 'Error'};
		}
	}
	else
	{
		$result = {raw => "Property: $property_name. Unrecognized action: $action. Must be one of 'add', 'update' or 'delete'", type => 'Error'};
	}

	return
	{
		properties_table	=> $self -> read_properties_table,
		message				=> $self -> format_raw_message($result),
		property_menu		=> $self -> build_properties_property_menu($self -> read_table('properties'), 'properties_property_menu', $$result{property_id}),
	};

} # End of process_property.

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

sub read_features_table
{
	my($self)		= @_;
	my($constants)	= $self -> constants;

	my($record, @records);

	for my $feature (@{$self -> read_table('features')})
	{
		$record	= {};

		for my $key (keys %$feature)
		{
			$$record{$key} = $$feature{$key};
		}

		$$record{icon_dir}	= "$$constants{homepage_dir}$$constants{icon_dir}";
		$$record{icon_file}	= $self -> clean_up_icon_name($$feature{name});
		$$record{icon_url}	= "$$constants{homepage_url}$$constants{icon_url}/$$record{icon_file}.png";

		for my $table_name (qw/feature_locations/)
		{
			$$record{$table_name} = $self -> read_feature_dependencies($table_name, $$record{id});
		}

		push @records, $record;
	}

	# Return an arrayref of hashrefs.

	return [sort{$$a{name} cmp $$b{name} } @records];

} # End of read_features_table.

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


		for my $table_name (qw/flower_locations feature_locations/)
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

sub read_properties_table
{
	my($self)		= @_;
	my($constants)	= $self -> constants;

	# Return an arrayref of hashrefs.

	return [sort{$$a{name} cmp $$b{name} } @{$self -> read_table('properties')}];

} # End of read_properties_table.

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
