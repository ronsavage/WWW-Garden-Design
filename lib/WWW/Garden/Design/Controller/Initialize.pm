package WWW::Garden::Design::Controller::Initialize;

use Mojo::Base 'Mojolicious::Controller';

use Moo;

our $VERSION = '1.00';

# -----------------------------------------------

sub build_check_boxes
{
	my($self, $db, $attribute_types, $kind) = @_;

	my(@html);
	my($id);
	my($name);
	my(@value_set);

	my(@check_boxes) = map
						{
							$name		= $$_{name};
							@value_set	= split(/,\s+/, $$_{range});
							@html		= map
											{
												$id = "${kind}_${name}_$_";
												$id =~ s/ /_/g;

												"<input id = '$id' type = 'checkbox'>"
												. "<label for = '$id'>$_</label>"
											} @value_set;
							$name	=~ s/_/&nbsp;/g;

							[ucfirst $name, join '&nbsp;&nbsp;&nbsp', @html];
						} sort{$$a{sequence} <=> $$b{sequence} } @$attribute_types;

	return [@check_boxes];

} # End of build_check_boxes.

# -----------------------------------------------

sub homepage
{
	my($self) = @_;

	$self -> app -> log -> debug('homepage()');

	my($defaults)				= $self -> app -> defaults;
	my($attribute_types)		= $$defaults{db} -> read_table('attribute_types');

	$self -> stash(attribute_check_boxes => $self -> build_check_boxes($$defaults{db}, $attribute_types, 'attribute') );
	$self -> stash(search_check_boxes => $self -> build_check_boxes($$defaults{db}, $attribute_types, 'search') );
	$self -> render(constants => $$defaults{db} -> read_constants_table);

} # End of homepage.

# -----------------------------------------------

1;
