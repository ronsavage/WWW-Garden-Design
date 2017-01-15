package WWW::Garden::Design::Controller::Garden;

use Mojo::Base 'Mojolicious::Controller';

use Date::Simple;

use Moo;

our $VERSION = '0.95';

# -----------------------------------------------

sub display
{
	my($self) = @_;

	$self -> app -> log -> debug('Garden.display()');

	my($item) =
	{
		description => $self -> param('description'),
		garden_name => $self -> param('garden_name'),
	};

	$self -> app -> log -> debug("param($_) => $$item{$_}") for sort keys %$item;

	if ($$item{description} && $$item{garden_name})
	{
		my($defaults)  = $self -> app -> defaults;

		$$defaults{db} -> add($item);

		$self -> stash(error	=> undef);
		$self -> stash(garden	=> $self -> format($item) );
	}
	else
	{
		my($message) = 'Missing garden name or description';

		$self -> stash(error	=> $message);
		$self -> stash(garden	=> undef);
		$self -> app -> log -> error($message);
	}

	$self -> render;

} # End of display.

# -----------------------------------------------

sub format
{
	my($self, $item) = @_;

	$self -> app -> log -> debug('Garden.format(...)');

	my($html) = <<EOS;
<tr>
	<td>$$item{name}</td>
	<td>$$item{description}</td>
</tr>
EOS

	return $html;

} # End of format.

# -----------------------------------------------

1;
