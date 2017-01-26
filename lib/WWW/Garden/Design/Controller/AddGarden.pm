package WWW::Garden::Design::Controller::AddGarden;

use Mojo::Base 'Mojolicious::Controller';

use Moo;

our $VERSION = '0.95';

# -----------------------------------------------

sub display
{
	my($self) = @_;

	$self -> app -> log -> debug('display()');

	my($item) =
	{
		garden_description		=> $self -> param('garden_description')   || '-',
		garden_name				=> $self -> param('garden_name'), # No default. See 'if' below.
		property_description	=> $self -> param('property_description') || '-',
		property_name			=> $self -> param('property_name'), # No default. See 'if' below.
	};

	$self -> app -> log -> debug("param($_) => $$item{$_}") for sort keys %$item;

	if ($$item{garden_name} && $$item{property_name})
	{
		my($defaults) = $self -> app -> defaults;

		$$defaults{db} -> add_garden($item);

		$self -> stash(error	=> undef);
		$self -> stash(message	=> 'Data saved');
	}
	else
	{
		my($message) = 'Missing property or garden name';

		$self -> stash(error	=> $message);
		$self -> stash(message	=> undef);
		$self -> app -> log -> error($message);
	}

	$self -> render;

} # End of display.

# -----------------------------------------------

1;
