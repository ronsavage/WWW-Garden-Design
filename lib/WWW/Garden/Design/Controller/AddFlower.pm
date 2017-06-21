package WWW::Garden::Design::Controller::AddFlower;

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper::Concise; # For Dumper().

use Date::Simple;

use Moo;

use URI::Find::Schemeless;

use utf8;

our $VERSION = '0.95';

# -----------------------------------------------
# https://github.com/kraih/mojo/wiki/Request-data.

sub display
{
	my($self) = @_;

	$self -> app -> log -> debug('AddFlower.display()');

	my($defaults)	= $self -> app -> defaults;
	my($params)		= $$defaults{validate_form} -> flower_details($self, $defaults);

	if ($$params{status} == 0)
	{
#		$$defaults{db} -> add_flower($params);

		$self -> stash(error	=> undef);
		$self -> stash(details	=> $self -> format($params) );
	}
	else
	{
		$self -> stash(error	=> $$params{message});
		$self -> stash(details	=> undef);
		$self -> app -> log -> error($$params{message});
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
