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
	(	# Form field		Table column		Table name.
		aliases			=> ['aliases',			'flowers'],
		color_code		=> ['hex',				'colors'],
		color_name		=> ['name',				'colors'],
		common_name		=> ['common_name',		'flowers'],
		garden_name		=> ['name',				'gardens'],
		object_name		=> ['name',				'objects'],
		scientific_name	=> ['scientific_name',	'flowers'],
	);
	my(%want_single_item) =
	(
		color_code	=> 1,
		color_name	=> 1,
		garden_name	=> 1,
	);

	my($defaults) = $self -> app -> defaults;

	if ($want_single_item{$type})
	{
		$self -> render(json => $$defaults{db} -> get_autocomplete_item(\%context, $type, uc $key) );
	}
	else
	{
		$self -> render(json => $$defaults{db} -> get_autocomplete_list(\%context, $type, uc $key) );
	}

} # End of display.

# -----------------------------------------------

1;
