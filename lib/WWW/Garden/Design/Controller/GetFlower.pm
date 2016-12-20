package WWW::Garden::Design::Controller::GetFlower;

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper::Concise; # For Dumper().

use Date::Simple;

use Moo;

our $VERSION = '1.06';

# -----------------------------------------------

sub display
{
	my($self)		= @_;
	my($flower_id)	= $self -> param('flower_id') || 0;

	$self -> app -> log -> debug("display(flower_id => $flower_id)");

	if ($flower_id > 0)
	{
		my($defaults)	= $self -> app -> defaults;
		my($json)		= $$defaults{db} -> read_flower_by_id($flower_id);

		$self -> app -> log -> info('read_flower_by_id: ' . Dumper($json) );
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
