package WWW::Garden::Design::Controller::AddGarden;

use Mojo::Base 'Mojolicious::Controller';

use Moo;

our $VERSION = '0.95';

# -----------------------------------------------

sub display
{
	my($self) = @_;

	$self -> app -> log -> debug('AddGarden.display()');

	my(@params)	= qw/garden_description garden_name garden_publish property_description property_name property_publish/;
	my($items)	= {map {($_, $self -> param($_) )} @params};

	$self -> app -> log -> debug("param($_) => $$items{$_}") for sort keys %$items;

	if ($$items{garden_name} && $$items{property_name})
	{
		my($defaults) = $self -> app -> defaults;

#		$$defaults{db} -> add_garden($items);

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
