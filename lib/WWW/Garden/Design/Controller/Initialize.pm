package WWW::Garden::Design::Controller::Initialize;

use Mojo::Base 'Mojolicious::Controller';

use Moo;

our $VERSION = '1.00';

# -----------------------------------------------

sub homepage
{
	my($self) = @_;

	$self -> app -> log -> debug('homepage()');

	my($defaults)			= $self -> app -> defaults;
	my($attribute_types)	= $$defaults{db} -> read_table('attribute_types');

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
												$id = "attribute_${name}_$_";
												$id =~ s/ /_/g;

												"<input id = '$id' type = 'checkbox'>"
												. "<label for = '$id'>$_</label>"
											} @value_set;
							$name	=~ s/_/&nbsp;/g;

							[ucfirst $name, join '&nbsp;&nbsp;&nbsp', @html];
						} sort{$$a{sequence} <=> $$b{sequence} } @$attribute_types;

	$self -> stash(check_boxes => \@check_boxes);
	$self -> render(constants => $$defaults{db} -> read_constants_table);

} # End of homepage.

# -----------------------------------------------

1;
