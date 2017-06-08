package WWW::Garden::Design::Validation::Base;

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Mojolicious::Validator;

use Moo;

use Types::Standard qw/Object/;

has validation =>
(
	is			=> 'ro',
	isa			=> Object,
	required	=> 1,
);

has validator =>
(
	default		=> sub{return Mojolicious::Validator -> new},
	is			=> 'ro',
	isa			=> Object,
	required	=> 1,
);

our $VERSION = '0.95';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

	$self -> validation($self -> validator -> validation);

} # End of BUILD.

# -----------------------------------------------

1;
