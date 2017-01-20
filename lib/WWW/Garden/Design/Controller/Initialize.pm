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

sub homepage
{
	my($self) = @_;

	$self -> app -> log -> debug('Initialize.homepage()');

	my($defaults) = $self -> app -> defaults;

	$self -> stash(attribute_check_boxes	=> $self -> build_check_boxes($$defaults{attribute_type_names}, $$defaults{attribute_type_fields}, $$defaults{attribute_attribute_ids}) );
	$self -> stash(csrf_token				=> $self -> session('csrf_token') );
	$self -> stash(search_check_boxes		=> $self -> build_check_boxes($$defaults{attribute_type_names}, $$defaults{attribute_type_fields}, $$defaults{search_attribute_ids}) );

	$self -> render(constants => $$defaults{constants_table}, gardens => $$defaults{gardens_table});

} # End of homepage.

# -----------------------------------------------

1;
