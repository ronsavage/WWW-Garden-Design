package WWW::Garden::Design::Controller::GetPropertyMenu;

use Mojo::Base 'Mojolicious::Controller';

use Date::Simple;

use Moo;

our $VERSION = '0.95';

# -----------------------------------------------

sub display
{
	my($self) = @_;

	$self -> app -> log -> debug('GetPropertyMenu.display()');

	my($defaults)			= $self -> app -> defaults;
	my($property_gardens)	= $$defaults{db} -> read_gardens_table; # Warning: Not read_table('gardens').

	$self -> stash(property_menu => $$defaults{property_menu});
	$self -> render;

} # End of display.

# -----------------------------------------------

sub format
{
	my($self, $property_gardens) = @_;

	$self -> app -> log -> debug('GetPropertyMenu.format(...)');

	my($html)		= "<select name = 'property' id = 'property'>";
	my($last_name)	= '';

	for my $garden (@$property_gardens)
	{
		if ($last_name eq '')
		{
			$self -> session(default_property_id => $$garden{property_id});
			$self -> app -> log -> debug("Setting default_property_id => $$garden{property_id}");
		}

		next if ($last_name eq $$garden{property_name});

		$html		.= "<option value = '$$garden{property_id}'>$$garden{property_name}</option>";
		$last_name	= $$garden{property_name};
	}

	return $html;

} # End of format.

# -----------------------------------------------

1;
