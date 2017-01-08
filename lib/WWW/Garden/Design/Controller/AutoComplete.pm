package WWW::Garden::Design::Controller::AutoComplete;

use Mojo::Base 'Mojolicious::Controller';

use Moo;

our $VERSION = '0.95';

# -----------------------------------------------

sub display
{
	my($self)		= @_;
	my($key)		= $self -> param('term')	|| ''; # jquery forces use of 'term'.
	my($type)		= $self -> param('type')	|| '';
	my(%context)	=
	(	#					Column				Table
		aliases			=> ['aliases',			'flowers'],
		common_name		=> ['common_name',		'flowers'],
		scientific_name	=> ['scientific_name',	'flowers'],
	);
	my($defaults) = $self -> app -> defaults;

	$self -> render(json => $$defaults{db} -> get_autocomplete_list(\%context, $type, uc $key) );

} # End of display.

# -----------------------------------------------

1;
