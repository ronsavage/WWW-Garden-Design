package WWW::Garden::Design::Controller::Initialize;

use Mojo::Base 'Mojolicious::Controller';

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

	my($defaults)					= $self -> app -> defaults;
	$$defaults{gardens_table}		= $$defaults{db} -> read_gardens_table; # Warning: Not read_table('gardens').
	$$defaults{objects_table}		= $$defaults{db} -> read_objects_table; # Warning: Not read_table('objects').
	$$defaults{properties_table}	= $$defaults{db} -> read_table('properties');
	my($attribute_elements)			= $self -> build_js_for_attributes($$defaults{attribute_type_names}, $$defaults{attribute_type_fields});

	# Warning: build_property_menu() sets a value in the session read by build_garden_menu(),
	# so it must be called first.
	#
	# A note on the property menus on the Gardens tab:
	# o garden_property_menu_1 => Properties which have gardens.
	# o garden_property_menu_2 => All properties, since any property is allowed to have gardens added.
	# Also, when a new property is added, only the latter menu gets updated (on the Gardens page).
	# And when a garden is added, the garden_garden_menu menu is updated (on the Gardens page),
	# as well as the garden menu on the Design page, i.e. the design_garden_menu.

	$$defaults{design_property_menu}	= $$defaults{db} -> build_property_menu($$defaults{gardens_table}, $self, 'design_property_menu');
	$$defaults{design_garden_menu}		= $$defaults{db} -> build_garden_menu($$defaults{gardens_table}, $self, 'design_garden_menu');
	$$defaults{full_property_menu}		= $$defaults{db} -> build_full_property_menu($$defaults{properties_table}, 'full_property_menu', 0);
	$$defaults{garden_property_menu_1}	= $$defaults{db} -> build_property_menu($$defaults{gardens_table}, $self, 'garden_property_menu_1');
	$$defaults{garden_property_menu_2}	= $$defaults{db} -> build_full_property_menu($$defaults{properties_table}, 'garden_property_menu_2', 0);
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
		full_property_menu		=> $$defaults{full_property_menu},
		garden_garden_menu		=> $$defaults{garden_garden_menu},
		garden_property_menu_1	=> $$defaults{garden_property_menu_1},
		garden_property_menu_2	=> $$defaults{garden_property_menu_2},
		joiner					=> $$defaults{joiner},
		object_menu				=> $$defaults{object_menu},
	);

} # End of homepage.

# -----------------------------------------------

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
