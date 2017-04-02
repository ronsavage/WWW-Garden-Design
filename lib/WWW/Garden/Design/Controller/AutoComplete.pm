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
		common_name		=> ['common_name',		'flowers'],
		design_flower	=> ['scientific_name',	'flowers'],
		design_object	=> ['name',				'objects'],
		garden_name		=> ['name',				'gardens'],
		object_name		=> ['name',				'objects'],
		property_name	=> ['name',				'properties'],
		scientific_name	=> ['scientific_name',	'flowers'],
	);
	my(%want_single_item) =
	(
		garden_name		=> 1,
		property_name	=> 1,
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
