package WWW::Garden::Design::Controller::Initialize;

use Mojo::Base 'Mojolicious::Controller';

use Moo;

use Data::Dumper::Concise; # For Dumper().

our $VERSION = '0.96';

# -----------------------------------------------

sub build_attribute_ids
{
	my($self, $kind, $attribute_type_fields, $attribute_type_names) = @_;

	my($id);
	my($name);

	return
	[
		map
		{
			$name = $$attribute_type_names[$_];
			[
				map
				{
					$id = "${kind}_${name}_$_" =~ s/ /_/gr;
					$id	=~ s/-/_/g;

					$id;
				} @{$$attribute_type_fields{$name} }
			]
		} 0 .. $#$attribute_type_names
	];

} # End of build_attribute_ids.

# -----------------------------------------------

sub build_attribute_type_fields
{
	my($self, $attribute_types_table) = @_;

	my(%attribute_type_fields);

	for (sort{$$a{sequence} <=> $$b{sequence} } @$attribute_types_table)
	{
		$attribute_type_fields{$$_{name} } = [split(/\s*,\s+/, $$_{range})];
	}

	return \%attribute_type_fields;

} # End of build_attribute_type_fields.

# -----------------------------------------------

sub build_attribute_type_names
{
	my($self, $attribute_types_table) = @_;

	my(@fields);
	my($name);

	return [map{$$_{name} } sort{$$a{sequence} <=> $$b{sequence} } @$attribute_types_table];

} # End of build_attribute_type_names.

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

	# Stash some gobal variables.

	$self -> app -> init_db; # Lives in WWW::Garden::Design::Database::Pg.

	my($defaults)						= {db => $self -> app -> db};
	$$defaults{constants_table}			= $self -> app -> read_constants_table; # Warning: Not read_table('constants').
	$$defaults{attributes_table}		= $self -> app -> read_table('attributes');
	$$defaults{attribute_types_table}	= $self -> app -> read_table('attribute_types');
	$$defaults{attribute_type_names}	= $self -> build_attribute_type_names($$defaults{attribute_types_table});
	$$defaults{attribute_type_fields}	= $self -> build_attribute_type_fields($$defaults{attribute_types_table});
	$$defaults{attribute_attribute_ids}	= $self -> build_attribute_ids('attribute', $$defaults{attribute_type_fields}, $$defaults{attribute_type_names});
	my($attribute_elements)				= $self -> build_js_for_attributes($$defaults{attribute_type_names}, $$defaults{attribute_type_fields});
	$$defaults{features_table}			= $self -> app -> read_features_table;	# Warning: Not read_table('features').
	$$defaults{gardens_table}			= $self -> app -> read_gardens_table;	# Warning: Not read_table('gardens').
	$$defaults{properties_table}		= $self -> app -> read_table('properties');
	$$defaults{search_attribute_ids}	= $self -> build_attribute_ids('search', $$defaults{attribute_type_fields}, $$defaults{attribute_type_names});

	$self -> app -> constants($$defaults{constants_table});

	# Warning: build_gardens_property_menu() sets a value in the session read by build_garden_menu(),
	# so it must be called first.
	#
	# A note on the property menus on the Gardens tab:
	# o gardens_property_menu_1 => Properties which have gardens.
	# o gardens_property_menu_2 => All properties, since any property is allowed to have gardens added.
	# Also, when a new property is added, only the latter menu gets updated (on the Gardens page).
	# And when a garden is added, the gardens_garden_menu menu is updated (on the Gardens page),
	# as well as the garden menu on the Design page, i.e. the design_garden_menu.

	$$defaults{design_property_menu}		= $self -> app -> build_gardens_property_menu($self, $$defaults{gardens_table}, 'design_property_menu', 0);
	$$defaults{design_garden_menu}			= $self -> app -> build_garden_menu($self, $$defaults{gardens_table}, 'design_garden_menu');
	$$defaults{feature_menu}				= $self -> app -> build_feature_menu($$defaults{features_table}, 0);
	$$defaults{gardens_property_menu_1}		= $self -> app -> build_gardens_property_menu($self, $$defaults{gardens_table}, 'gardens_property_menu_1', 0);
	$$defaults{gardens_property_menu_2}		= $self -> app -> build_properties_property_menu($$defaults{properties_table}, 'gardens_property_menu_2', 0);
	$$defaults{gardens_garden_menu}			= $self -> app -> build_garden_menu($self, $$defaults{gardens_table}, 'gardens_garden_menu');
	$$defaults{properties_property_menu}	= $self -> app -> build_properties_property_menu($$defaults{properties_table}, 'properties_property_menu', 0);

	$self -> app -> defaults($defaults);
	$self -> stash(attribute_check_boxes	=> $self -> build_check_boxes($$defaults{attribute_type_names}, $$defaults{attribute_type_fields}, $$defaults{attribute_attribute_ids}) );
	$self -> stash(csrf_token				=> $self -> session('csrf_token') );
	$self -> stash(search_check_boxes		=> $self -> build_check_boxes($$defaults{attribute_type_names}, $$defaults{attribute_type_fields}, $$defaults{search_attribute_ids}) );

	# Find the id of the 1st property on the Properties tab.
	# This is needed to initialize a JS variable of the same name,
	# and the corresponding JS variable of the 2nd property menu on the Gardens tab.
	# And we sort the properties because the property menu is sorted, and we default to the 1st item.

	@{$$defaults{properties_table} } 	= sort{$$a{name} cmp $$b{name} } @{$$defaults{properties_table} };
	my($properties_current_property_id)	= $$defaults{properties_table}[0]{id};

	# Find the id of the 1st garden on the Gardens tab. It is sorted in Database.read_gardens_table().

	my($gardens_current_garden_id)		= $$defaults{gardens_table}[0]{id};
	my($gardens_current_property_id_1)	= $$defaults{gardens_table}[0]{property_id};

	# Find the id of the 1st feature on the Features tab.

	my($features_current_feature_id) = $$defaults{features_table}[0]{id};

	# These parameters are passed to homepage.html.ep for incorporation into JS code.

	$self -> render
	(
		attribute_elements				=> $attribute_elements,
		constants						=> $$defaults{constants_table},
		design_garden_menu				=> $$defaults{design_garden_menu},
		design_property_menu			=> $$defaults{design_property_menu},
		features_current_feature_id		=> $features_current_feature_id,
		feature_menu					=> $$defaults{feature_menu},
		gardens_current_garden_id		=> $gardens_current_garden_id,
		gardens_current_property_id_1	=> $gardens_current_property_id_1,
		gardens_current_property_id_2	=> $properties_current_property_id,
		gardens_garden_menu				=> $$defaults{gardens_garden_menu},
		gardens_property_menu_1			=> $$defaults{gardens_property_menu_1},
		gardens_property_menu_2			=> $$defaults{gardens_property_menu_2},
		joiner							=> '«»',
		properties_current_property_id	=> $properties_current_property_id,
		properties_property_menu		=> $$defaults{properties_property_menu},
		version							=> $VERSION,
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
