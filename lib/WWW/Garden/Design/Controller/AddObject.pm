package WWW::Garden::Design::Controller::AddObject;

use Mojo::Base 'Mojolicious::Controller';

use Moo;

our $VERSION = '0.95';

# -----------------------------------------------

sub display
{
	my($self) = @_;

	$self -> app -> log -> debug('AddObject.display()');

	my($item) =
	{
		color_chosen	=> $self -> param('color_chosen')	|| '',
		color_code		=> $self -> param('color_code')		|| '',
		color_name		=> $self -> param('color_name')		|| '',
		object_name		=> $self -> param('object_name')	|| '',
		object_publish	=> $self -> param('object_publish')	|| '',
	};

	$self -> app -> log -> debug("param($_) => $$item{$_}") for sort keys %$item;

	if ($$item{color_chosen} && $$item{object_name})
	{
		my($defaults) = $self -> app -> defaults;

#		$$defaults{db} -> add_object($item);

		$self -> stash(error => undef);
	}
	else
	{
		my($message) = 'Missing color name or object name';

		$self -> stash(error => $message);
		$self -> app -> log -> error($message);
	}

	$self -> render;

} # End of display.

# -----------------------------------------------

1;
