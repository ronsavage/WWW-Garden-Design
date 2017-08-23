package WWW::Garden::Design::Controller::Design;

use Mojo::Base 'Mojolicious::Controller';

use Moo;

use WWW::Garden::Design::Util::ValidateForm

our $VERSION = '0.95';

# -----------------------------------------------

sub save
{
	my($self) = @_;

	$self -> app -> log -> debug('Design.save()');

	my($defaults)	= $self -> app -> defaults;
	my($validator)	= WWW::Garden::Design::Util::ValidateForm -> new;
	my($params)		= $validator -> design_details($self, $defaults);

=pod

	if ($$items{garden_name} && $$items{property_name})
	{
		my($defaults) = $self -> app -> defaults;

#		$$defaults{db} -> add_garden($items);

		$self -> stash(error => undef);
	}
	else
	{
		my($message) = 'Missing property or garden name';

		$self -> stash(error => $message);
		$self -> app -> log -> error($message);
	}

=cut

	$self -> render;

} # End of save.

# -----------------------------------------------

1;
