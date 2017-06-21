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
#	attributes['Native']		= ['No', 'Yes', 'Unknown'];
#	attributes['Sun tolerance']	= ['Full_sun', 'Part_shade', 'Shade', 'Unknown'];

sub build_js_for_attributes
{
	my($self, $type_names, $type_fields)	= @_;
	my($attribute_elements)					= "\tvar attributes = new Object;\n\n";

	my($temp_name);

	for my $type_name (sort @$type_names)
	{
		$temp_name			= $type_name =~ s/ /_/gr;
		$attribute_elements	.= "\tattributes['$temp_name'] = ["
								. join(', ', map{"'$_'"} @{$$type_fields{$type_name} })
								. "];\n";
	}

	return $attribute_elements;

} # End of build_js_for_attributes.

# -----------------------------------------------

sub homepage
{
	my($self) = @_;

	$self -> app -> log -> debug('Initialize.homepage()');

	my($defaults)				= $self -> app -> defaults;
	$$defaults{gardens_table}	= $$defaults{db} -> read_gardens_table; # Warning: Not read_table('gardens').
	$$defaults{objects_table}	= $$defaults{db} -> read_objects_table; # Warning: Not read_table('objects').
	my($attribute_elements)		= $self -> build_js_for_attributes($$defaults{attribute_type_names}, $$defaults{attribute_type_fields});

	# Warning: build_property_menu() sets a value in the session read by build_garden_menu(),
	# so it must be called first.

	$$defaults{design_property_menu}	= $$defaults{db} -> build_property_menu($$defaults{gardens_table}, $self, 'design_property_menu');
	$$defaults{design_garden_menu}		= $$defaults{db} -> build_garden_menu($$defaults{gardens_table}, $self, 'design_garden_menu');
	$$defaults{garden_property_menu}	= $$defaults{db} -> build_property_menu($$defaults{gardens_table}, $self, 'garden_property_menu');
	$$defaults{garden_garden_menu}		= $$defaults{db} -> build_garden_menu($$defaults{gardens_table}, $self, 'garden_garden_menu');
	$$defaults{object_menu}				= $$defaults{db} -> build_object_menu($$defaults{objects_table}, $self);

	$self -> app -> defaults($defaults);
	$self -> stash(attribute_check_boxes	=> $self -> build_check_boxes($$defaults{attribute_type_names}, $$defaults{attribute_type_fields}, $$defaults{attribute_attribute_ids}) );
	$self -> stash(csrf_token				=> $self -> session('csrf_token') );
	$self -> stash(search_check_boxes		=> $self -> build_check_boxes($$defaults{attribute_type_names}, $$defaults{attribute_type_fields}, $$defaults{search_attribute_ids}) );

	# These parameters are passed to homepage.html.ep for incorporation into JS code.

	$self -> render
	(
		attribute_elements		=> $attribute_elements,
		constants				=> $$defaults{constants_table},
		design_garden_menu		=> $$defaults{design_garden_menu},
		design_property_menu	=> $$defaults{design_property_menu},
		garden_garden_menu		=> $$defaults{garden_garden_menu},
		garden_property_menu	=> $$defaults{garden_property_menu},
		joiner					=> $$defaults{joiner},
		object_menu				=> $$defaults{object_menu},
	);

} # End of homepage.

# -----------------------------------------------

1;
