package WWW::Garden::Design::Controller::Initialize;

use Mojo::Base 'Mojolicious::Controller';

use Moo;

our $VERSION = '1.00';

# -----------------------------------------------

sub build_check_boxes
{
	my($self, $names, $fields, $ids) = @_;

	my($field);
	my(@html);
	my($id_index, $id);
	my($name_index, $name);

	my(@check_boxes) = map
						{
							$name_index	= $_;
							$name		= ucfirst $$names[$name_index] =~ s/_/&nbsp;/gr;
							@html		= map
											{
												$id_index	= $_;
												$field			= $$fields[$name_index][$id_index] =~ s/_/&nbsp;/gr;
												$id				= $$ids[$name_index][$id_index];

												"<input id = '$id' type = 'checkbox'>"
												. "<label for = '$id'>$field</label>";
											} 0 .. $#{$$ids[$name_index]};

							[$name, join('&nbsp;&nbsp;&nbsp', @html)];
						} 0 .. $#$names;

	return [@check_boxes];

} # End of build_check_boxes.

# -----------------------------------------------

sub homepage
{
	my($self) = @_;

	$self -> app -> log -> debug('homepage()');

	my($defaults) = $self -> app -> defaults;

	$self -> stash(attribute_check_boxes => $self -> build_check_boxes($$defaults{attribute_type_names}, $$defaults{attribute_type_fields}, $$defaults{attribute_attribute_ids}) );
	$self -> stash(search_check_boxes => $self -> build_check_boxes($$defaults{attribute_type_names}, $$defaults{attribute_type_fields}, $$defaults{search_attribute_ids}) );
	$self -> render(constants => $$defaults{db} -> read_constants_table);

} # End of homepage.

# -----------------------------------------------

1;
