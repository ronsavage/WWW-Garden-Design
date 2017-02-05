package WWW::Garden::Design::Controller::GetPropertyDetails;

use Mojo::Base 'Mojolicious::Controller';

use Date::Simple;

use Moo;

our $VERSION = '0.95';

# -----------------------------------------------

sub display
{
	my($self) = @_;

	$self -> app -> log -> debug('GetPropertyDetails.display()');

	my($defaults)			= $self -> app -> defaults;
	my($property_gardens)	= $$defaults{db} -> read_gardens_table; # Warning: Not read_table('gardens').

	$self -> stash(property_menu => $$defaults{property_menu});
	$self -> render;

} # End of display.

# -----------------------------------------------

sub format
{
	my($self, $property_gardens) = @_;

	$self -> app -> log -> debug('GetPropertyDetails.format(...)');

	my($html)		= "<select name = 'property_menu' id = 'property_menu'>";
	my($last_name)	= '';

	for my $garden (@$property_gardens)
	{
		if ($last_name eq '')
		{
			$self -> app -> session(current_property_id => $$garden{property_id});
			$self -> app -> log -> debug("Setting current_property_id => $$garden{property_id}");
		}

		next if ($last_name eq $$garden{property_name});

		$html		.= "<option value = '$$garden{property_id}'>$$garden{property_name}</option>";
		$last_name	= $$garden{property_name};
	}

	return $html;

} # End of format.

# -----------------------------------------------

1;
