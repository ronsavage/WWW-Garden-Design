package WWW::Garden::Design::Database::Users;

use strict;
use warnings;

use Mojo::Util 'secure_compare';

use Moo;

our $VERSION = '0.96';

my %USERS = (ron => 'savage');

# --------------------------------------------------

sub check
{
	my($self, $username, $password) = @_;

	return exists($USERS{$username}) && (secure_compare($USERS{$username}, $password) ) ? 1 : 0;

} # End of check.

# --------------------------------------------------

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

Australian copyright (c) 2018, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
