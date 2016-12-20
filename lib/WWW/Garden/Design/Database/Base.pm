package WWW::Garden::Design::Database::Base;

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Moo;

use Types::Standard qw/Object/;

extends qw/WWW::Garden::Design::Util::Config/;

has db =>
(
	is       => 'rw',
	isa      => Object, # 'WWW::Garden::Design::Database'.
	required => 0,
);

our $VERSION = '1.06';

# -----------------------------------------------

1;
