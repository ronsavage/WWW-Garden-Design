package WWW::Garden::Design::Controller::GetPropertyGardens;

use Mojo::Base 'Mojolicious::Controller';

use Date::Simple;

use Moo;

our $VERSION = '0.95';

# -----------------------------------------------

sub display
{
	my($self) = @_;

	$self -> app -> log -> debug('GetPropertyGardens.display()');

	my($defaults) = $self -> app -> defaults;
	my($property_gardens)	= $$defaults{db} -> read_gardens_table; # Warning: Not read_table('gardens').

	$self -> stash(property_gardens => $self -> format($property_gardens) );
	$self -> render;

} # End of display.

# -----------------------------------------------

sub format
{
	my($self, $property_gardens) = @_;

	$self -> app -> log -> debug('GetPropertyGardens.format(...)');

	my($html)			= '';
	my($last_property)	= '';
	my($property_name)	= '';

	for my $garden (@$property_gardens)
	{
		if ($last_property eq $$garden{property_name})
		{
			$property_name = '&nbsp;&nbsp;&nbsp;&nbsp;"';
		}
		else
		{
			$last_property = $property_name = $$garden{property_name};
		}

		$html .= <<EOS;
		<tr>
			<td class = 'generic_border generic_padding'>$property_name</td>
			<td class = 'generic_border generic_padding'>$$garden{name}</td>
		</tr>
EOS
	}

	return $html;

} # End of format.

# -----------------------------------------------

1;
