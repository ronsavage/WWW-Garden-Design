package WWW::Garden::Design::Controller::AddGarden;

use Mojo::Base 'Mojolicious::Controller';

use Moo;

our $VERSION = '0.95';

# -----------------------------------------------

sub display
{
	my($self) = @_;

	$self -> app -> log -> debug('AddGarden.display()');

	my($item) =
	{
		garden_description		=> $self -> param('garden_description')		|| '-',
		garden_name				=> $self -> param('garden_name')			|| '',
		garden_publish			=> $self -> param('garden_publish')			|| '',
		property_description	=> $self -> param('property_description')	|| '-',
		property_name			=> $self -> param('property_name')			|| '',,
		property_publish		=> $self -> param('property_publish')		|| '',
	};

	$self -> app -> log -> debug("param($_) => $$item{$_}") for sort keys %$item;

	if ($$item{garden_name} && $$item{property_name})
	{
		my($defaults) = $self -> app -> defaults;

#		$$defaults{db} -> add_garden($item);

		$self -> stash(error => undef);
	}
	else
	{
		my($message) = 'Missing property or garden name';

		$self -> stash(error => $message);
		$self -> app -> log -> error($message);
	}

	$self -> render;

} # End of display.

# -----------------------------------------------

1;
