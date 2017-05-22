package WWW::Garden::Design::Controller::AddFlower;

use Mojo::Base 'Mojolicious::Controller';

use Date::Simple;

use Moo;

our $VERSION = '0.95';

# -----------------------------------------------

sub display
{
	my($self) = @_;

	$self -> app -> log -> debug('AddFlower.display()');

	my($item) =
	{
		aliases				=> $self -> param('aliases')			|| '-',
		attribute_values	=> $self -> param('attribute_values')	|| '-',
		common_name			=> $self -> param('common_name')		|| '',
		height				=> $self -> param('height')				|| '-',
		scientific_name		=> $self -> param('scientific_name')	|| '',
		width				=> $self -> param('width')				|| '-',
	};

	$self -> app -> log -> debug("$_ => $$item{$_}") for sort keys %$item;

	if ($$item{common_name} && $$item{scientific_name})
	{
		my($defaults)  = $self -> app -> defaults;

		$$defaults{db} -> add_flower($item);

		$self -> stash(error	=> undef);
		$self -> stash(details	=> $self -> format($item) );
	}
	else
	{
		my($message) = 'Missing common name or scientific name';

		$self -> stash(error	=> $message);
		$self -> stash(details	=> undef);
		$self -> app -> log -> error($message);
	}

	$self -> render;

} # End of display.

# -----------------------------------------------

sub format
{
	my($self, $item) = @_;

	$self -> app -> log -> debug('Details.format(...)');

	my($html) = <<EOS;
<tr>
	<td>$$item{common_name}</td>
	<td>$$item{scientific_name}</td>
	<td>$$item{aliases}</td>
	<td>$$item{height}</td>
	<td>$$item{width}</td>
</tr>
EOS

	return $html;

} # End of format.

# -----------------------------------------------

1;
