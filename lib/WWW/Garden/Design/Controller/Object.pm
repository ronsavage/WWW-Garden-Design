package WWW::Garden::Design::Controller::Object;

use Mojo::Base 'Mojolicious::Controller';

use Date::Simple;

use Moo;

our $VERSION = '0.95';

# -----------------------------------------------

sub display
{
	my($self) = @_;

	$self -> app -> log -> debug('Object.display()');

	my($item) =
	{
		hidden_color	=> $self -> param('hidden_color'), # No defaults. See 'if' below.
		object_name		=> $self -> param('object_name'),
	};

	$self -> app -> log -> debug("param($_) => $$item{$_}") for sort keys %$item;

	if ($$item{object_name} && $$item{hidden_color})
	{
		my($defaults)  = $self -> app -> defaults;

		$$defaults{db} -> add($item);

		$self -> stash(error	=> undef);
		$self -> stash(object	=> $self -> format($item) );
	}
	else
	{
		my($message) = 'Missing object name or color';

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
