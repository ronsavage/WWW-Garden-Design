package WWW::Garden::Design::Controller::GetGardenMenu;

use Mojo::Base 'Mojolicious::Controller';

use Date::Simple;

use Moo;

our $VERSION = '0.95';

# -----------------------------------------------

sub display
{
	my($self) = @_;

	$self -> app -> log -> debug('GetGardenMenu.display()');

	my($defaults)			= $self -> app -> defaults;
	my($property_gardens)	= $$defaults{db} -> read_gardens_table; # Warning: Not read_table('gardens').

	$self -> stash(garden_menu => $$defaults{garden_menu});
	$self -> render;

} # End of display.

# -----------------------------------------------

sub format
{
	my($self, $property_gardens) = @_;

	$self -> app -> log -> debug('GetGardenMenu.format(...)');

	my($html)			= "<select name = 'garden_menu' id = 'garden_menu'>";
	my($last_name)		= '';
	my($property_id)	= $self -> app -> session('default_property_id');

	$self -> app -> log -> debug("Getting default_property_id => $property_id");

	for my $garden (@$property_gardens)
	{
		# This test assumes that within a property, all garden names are unique.
		# For the other type of test, see GetPropertyMenu.pm.

		next if ($property_id ne $$garden{property_id});

		$html		.= "<option value = '$$garden{id}'>$$garden{name}</option>";
		$last_name	= $$garden{name};
	}

	return $html;

} # End of format.

# -----------------------------------------------

1;
