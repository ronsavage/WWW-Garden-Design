package WWW::Garden::Design;

use Mojo::Base 'Mojolicious';

use WWW::Garden::Design::Database;
use WWW::Garden::Design::Util::Config;

use Moo;

our $VERSION = '1.06';

# ------------------------------------------------
# This method will run once at server start.

sub startup
{
	my $self = shift;

	$self -> secrets(['Passchar']);

	# Log a special line to make the start of each request easy to find in the log.
	# Of course, nothing is logged by this just because the server restarted.

	$self -> hook
	(
		before_dispatch =>
		sub
		{
			$self -> app -> log -> info('-' x 30);
		}
	);

	# Stash some gobal variables.

	my($default);

	$$default{config} = WWW::Garden::Design::Util::Config -> new -> config;
	$$default{db}     = WWW::Garden::Design::Database -> new(logger => $self -> app -> log);

	$self -> defaults($default);

	# Documentation browser under '/perldoc'.

	$self -> plugin('PODRenderer');
	$self -> plugin('ServerStatus' =>
				{
					allow       => ['127.0.0.1'],
					counterfile => '/tmp/mojolicious/counter.flowers.txt',
					path        => '/server-status',
					scoreboard  => '/tmp/mojolicious',
				});
	$self -> plugin('TagHelpers');

	# Router.

	my($r) = $self -> routes;

	# Normal route to controller.

	$r -> namespaces(['WWW::Garden::Design::Controller']);

	$r -> route('/')					-> to('Initialize#homepage');
	$r -> route('/Flower')				-> to('Flower#display');
	$r -> route('/GetAttributeTypes')	-> to('GetAttributeTypes#display');
	$r -> route('/GetFlower')			-> to('GetFlower#display');
	$r -> route('/Object')				-> to('Object#display');
	$r -> route('/AuoComplete')			-> to('AutoComplete#display');
	$r -> route('/Search')				-> to('Search#search');

} # End of startup.

# ------------------------------------------------

1;
