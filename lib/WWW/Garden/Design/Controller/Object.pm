package WWW::Garden::Design::Controller::Object;

use Mojo::Base 'Mojolicious::Controller';

use Date::Simple;

use Moo;

our $VERSION = '1.00';

# -----------------------------------------------

sub display
{
	my($self) = @_;

	$self -> app -> log -> debug('Object.display()');

	my($item) =
	{
		color	=> $self -> param('color'), # No defaults. See 'if' below.
		name	=> $self -> param('name'),
	};

	$self -> app -> log -> debug("param($_) => $$item{$_}") for sort keys %$item;

	if ($$item{name} && $$item{color})
	{
		my($defaults)  = $self -> app -> defaults;

		$$defaults{db} -> add($item);

		$self -> stash(error	=> undef);
		$self -> stash(object	=> $self -> format($item) );
	}
	else
	{
		my($message) = 'Missing name or color';

		$self -> stash(error	=> $message);
		$self -> stash(object	=> undef);
		$self -> app -> log -> error($message);
	}

	$self -> render;

} # End of display.

# -----------------------------------------------

sub format
{
	my($self, $item) = @_;

	$self -> app -> log -> debug('Object.format(...)');

	my($html) = <<EOS;
<tr>
	<td>$$item{name}</td>
	<td>$$item{color}</td>
</tr>
EOS

	return $html;

} # End of format.

# -----------------------------------------------

1;
