package WWW::Garden::Design::Controller::Initialize;

use Mojo::Base 'Mojolicious::Controller';

use Moo;

our $VERSION = '1.00';

# -----------------------------------------------

sub build_check_boxes
{
	my($self, $kind)		= @_;
	my($defaults)			= $self -> app -> defaults;
	my($attribute_fields)	= $$defaults{db} -> read_table('attribute_types');

	my(@html);
	my($id);
	my(@names, $name);
	my(@value_set);

	my(@check_boxes) = map
						{
							@names	= @$_;
							@html	= map
										{
											$name	= $_;
											$id		= "${kind}_$name";

											"<input id = '$id' type = 'checkbox'>"
											. "<label for = '$id'>$_</label>"
										} @names;
							$name	=~ s/_/&nbsp;/g;

							[ucfirst $name, join '&nbsp;&nbsp;&nbsp', @html];
						} @{$$defaults{attribute_fields} };

	return [@check_boxes];

} # End of build_check_boxes.

# -----------------------------------------------

sub homepage
{
	my($self) = @_;

	$self -> app -> log -> debug('homepage()');

	$self -> stash(attribute_check_boxes => $self -> build_check_boxes('attribute') );
	$self -> stash(search_check_boxes => $self -> build_check_boxes('search') );
	$self -> render(constants => $$defaults{db} -> read_constants_table);

} # End of homepage.

# -----------------------------------------------

1;
