package WWW::Garden::Design::Controller::Flower;

use Mojo::Base 'Mojolicious::Controller';

use Date::Simple;

use Moo;

our $VERSION = '1.00';

# -----------------------------------------------

sub display
{
	my($self) = @_;

	$self -> app -> log -> debug('Flower.display()');

	my($item) =
	{
		aliases			=> $self -> param('aliases') || '-',
		common_name		=> $self -> param('common_name'), # No default. See 'if' below.
		scientific_name	=> $self -> param('scientific_name'),
	};

	$self -> app -> log -> debug("param($_) => $$item{$_}") for sort keys %$item;

	if ($$item{common_name} && $$item{scientific_name})
	{
		my($defaults)  = $self -> app -> defaults;

		$$defaults{db} -> add($item);

		$self -> stash(error	=> undef);
		$self -> stash(flower	=> $self -> format($item) );
	}
	else
	{
		my($message) = 'Missing common name or scientific name';

		$self -> stash(error	=> $message);
		$self -> stash(flower	=> undef);
		$self -> app -> log -> error($message);
	}

	$self -> render;

} # End of display.

# -----------------------------------------------

sub format
{
	my($self, $item) = @_;

	$self -> app -> log -> debug('Flower.format(...)');

	my($html) = <<EOS;
<tr>
	<td>$$item{common_name}</td>
	<td>$$item{aliases}</td>
	<td>$$item{scientific_name}</td>
	<td>$$item{web_page_url}</td>
	<td>$$item{thumbnail_url}</td>
</tr>
EOS

	return $html;

} # End of format.

# -----------------------------------------------

1;
