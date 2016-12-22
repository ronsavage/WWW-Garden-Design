package WWW::Garden::Design::Controller::GetAttributeTypes;

use Mojo::Base 'Mojolicious::Controller';

use Date::Simple;

use Moo;

our $VERSION = '1.00';

# -----------------------------------------------

sub display
{
	my($self) = @_;

	$self -> app -> log -> debug('display()');

	my($defaults)	= $self -> app -> defaults;
	my($json)		= $$defaults{db} -> read_table('attribute_types');

	$self -> render(json => $json);


} # End of display.

# -----------------------------------------------

1;
