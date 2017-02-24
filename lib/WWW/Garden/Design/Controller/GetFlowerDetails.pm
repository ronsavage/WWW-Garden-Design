package WWW::Garden::Design::Controller::GetFlowerDetails;

use Mojo::Base 'Mojolicious::Controller';

use Date::Simple;

use Moo;

our $VERSION = '0.95';

# -----------------------------------------------

sub display
{
	my($self)		= @_;
	my($flower_id)	= $self -> param('flower_id') || 0;

	$self -> app -> log -> debug("GetFlowerDetails.display(flower_id => $flower_id)");

	if ($flower_id > 0)
	{
		my($defaults)	= $self -> app -> defaults;
		my($json)		= $$defaults{db} -> get_flower_by_id($flower_id);

		$self -> stash(error => undef);
		$self -> render(json => $json);
	}
	else
	{
		my($message) = "Error: Unknown key flower_id = $flower_id";

		$self -> app -> log -> error($message);
		$self -> stash(error => $message);
		$self -> render;
	}

} # End of display.

# -----------------------------------------------

1;