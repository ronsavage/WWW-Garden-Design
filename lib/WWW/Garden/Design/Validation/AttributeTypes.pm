package WWW::Garden::Design::Validation::AttributeTypes;

use base 'WWW::Garden::Design::Validation::Base';
use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Moo;

use Types::Standard qw/Object/;

our $VERSION = '0.95';

# -----------------------------------------------

sub init
{
	my($self) = @_;

}	# End of init.

# -----------------------------------------------

1;
