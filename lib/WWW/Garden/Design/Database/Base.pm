package WWW::Garden::Design::Database::Base;

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use boolean;

use Moo;

use Types::Standard qw/Object/;

extends 'WWW::Garden::Design::Util::Config';

has db =>
(
	is       => 'rw',
	isa      => Object, # 'WWW::Garden::Design::Database'.
	required => 0,
);

our $VERSION = '0.96';

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
			],
			'order': [ [1, 'asc'] ]
		});
	});
EOS

}	# End of init_datatable.

# -----------------------------------------------

1;

=pod

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/WWW-Garden-Design>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=WWW::Garden::Design>.

=head1 Author

L<WWW::Garden::Design> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2014.

My homepage: L<https://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2013, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
