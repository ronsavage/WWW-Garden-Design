package WWW::Garden::Design::Controller::AddProperty;

use Mojo::Base 'Mojolicious::Controller';

use Moo;

our $VERSION = '0.95';

# -----------------------------------------------

sub save
{
	my($self) = @_;

	$self -> app -> log -> debug('AddProperty.save()');

	my($item) = $self -> req -> params -> to_hash;

	$self -> app -> log -> debug("param($_) => $$item{$_}") for sort keys %$item;

	if ($$item{name})
	{
		my($defaults) = $self -> app -> defaults;

		$$defaults{db} -> process_property_submit($item);

		$self -> stash(error => undef);
	}
	else
	{
		my($message) = 'Missing property name';

		$self -> stash(error => $message);
		$self -> app -> log -> error($message);
	}

	$self -> render;

} # End of save.

# -----------------------------------------------

1;
