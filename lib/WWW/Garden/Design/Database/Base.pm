package WWW::Garden::Design::Database::Base;

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use boolean;

use Moo;

use Types::Standard qw/Object/;

extends qw/WWW::Garden::Design::Util::Config/;

has db =>
(
	is       => 'rw',
	isa      => Object, # 'WWW::Garden::Design::Database'.
	required => 0,
);

our $VERSION = '0.95';

# -----------------------------------------------

sub init_datatable
{
	my($self) = @_;

	return <<EOS;
	\$(function()
	{
		\$('#result_table').DataTable
		({
			'columnDefs':
			[
				{'cellType':'th','orderable':true,'searchable':true,'type':'html'},		// Native.
				{'cellType':'th','orderable':true,'searchable':true,'type':'html'},		// Scientific name.
				{'cellType':'th','orderable':true,'searchable':true,'type':'html'},		// Common name.
				{'cellType':'th','orderable':true,'searchable':true,'type':'html'},		// Aliases.
				{'cellType':'th','orderable':false,'searchable':false,'type':'html'}	// Thumbnail.
			]
		});
	});
EOS

}	# End of init_datatable.

# -----------------------------------------------

1;
