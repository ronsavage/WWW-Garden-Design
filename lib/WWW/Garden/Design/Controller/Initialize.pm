package WWW::Garden::Design::Controller::Initialize;

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper::Concise; # For Dumper().

use Moo;

our $VERSION = '0.95';

# -----------------------------------------------

sub build_check_boxes
{
	my($self, $type_names, $fields, $ids) = @_;

	my($field);
	my(@html);
	my($id_index, $id);
	my($name_index, $name);
	my($type_name);

	my(@check_boxes) = map
						{
							$name_index	= $_;
							$type_name	= $$type_names[$name_index];
							$name		= ucfirst $$type_names[$name_index] =~ s/_/&nbsp;/gr;
							@html		= map
											{
												$id_index	= $_;
												$field		= $$fields{$type_name}[$id_index] =~ s/_/&nbsp;/gr;
												$id			= $$ids[$name_index][$id_index];

												"<input id = '$id' type = 'checkbox'>"
												. "<label for = '$id'>$field</label>";
											} 0 .. $#{$$ids[$name_index]};

							[$name, join('&nbsp;&nbsp;&nbsp', @html)];
						} 0 .. $#$type_names;

	return [@check_boxes];

} # End of build_check_boxes.

# -----------------------------------------------

sub build_garden_menu
{
	my($self, $property_gardens) = @_;
	my($html)			= "<label for 'garden_menu'>Garden: </label><br />"
							. "<select name = 'garden_menu' id = 'garden_menu'>";
	my($last_name)		= '';
	my($property_id)	= $self -> session('current_property_id');

	for my $garden (@$property_gardens)
	{
		# This test assumes that within a property, all garden names are unique.
		# For the other type of test, see GetPropertyDetails.pm.

		next if ($property_id ne $$garden{property_id});

		if ($last_name eq '')
		{
			$self -> session(current_garden_id => $$garden{id});
			$self -> app -> log -> debug('Setting current_garden_id => ' . $self -> session('current_garden_id') );
		}

		$html		.= "<option value = '$$garden{id}'>$$garden{name}</option>";
		$last_name	= $$garden{name};
	}

	$html .= '</select>';

	return $html;

} # End of build_garden_menu.

# -----------------------------------------------

sub build_property_menu
{
	my($self, $property_gardens) = @_;
	my($html)		= "<label for 'property_menu'>Property: </label><br />"
						. "<select name = 'property_menu' id = 'property_menu'>";
	my($last_name)	= '';

	for my $garden (@$property_gardens)
	{
		if ($last_name eq '')
		{
			$self -> session(current_property_id => $$garden{property_id});
			$self -> app -> log -> debug('Setting current_property_id => ' . $self -> session('current_property_id') );
		}

		next if ($last_name eq $$garden{property_name});

		$html		.= "<option value = '$$garden{property_id}'>$$garden{property_name}</option>";
		$last_name	= $$garden{property_name};
	}

	$html .= '</select>';

	return $html;

} # End of build_property_menu.

# -----------------------------------------------

sub homepage
{
	my($self) = @_;

	$self -> app -> log -> debug('Initialize.homepage()');

	my($defaults)				= $self -> app -> defaults;
	$$defaults{gardens_table}	= $$defaults{db} -> read_gardens_table; # Warning: Not read_table('gardens').

	# build_property_menu() must precede build_garden_menu() because it stores current_property_id in the session.
	# And this code must appear in Initialize.pm because sessions don't exist in the main app, Design.pm.

	$$defaults{property_menu}	= $self -> build_property_menu($$defaults{gardens_table});
	$$defaults{garden_menu}		= $self -> build_garden_menu($$defaults{gardens_table});

	$self -> app -> defaults($defaults);
	$self -> stash(attribute_check_boxes	=> $self -> build_check_boxes($$defaults{attribute_type_names}, $$defaults{attribute_type_fields}, $$defaults{attribute_attribute_ids}) );
	$self -> stash(csrf_token				=> $self -> session('csrf_token') );
	$self -> stash(search_check_boxes		=> $self -> build_check_boxes($$defaults{attribute_type_names}, $$defaults{attribute_type_fields}, $$defaults{search_attribute_ids}) );

	$self -> render
	(
		constants		=> $$defaults{constants_table},
		garden_menu		=> $$defaults{garden_menu},
		property_menu	=> $$defaults{property_menu}
	);

} # End of homepage.

# -----------------------------------------------

1;
