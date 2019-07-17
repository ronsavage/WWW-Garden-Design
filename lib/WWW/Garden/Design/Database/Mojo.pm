package WWW::Garden::Design::Database::Mojo;

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Dumper::Concise; # For Dumper().

use Mojo::Collection;

use Moo;

use Types::Standard qw/Any/;

has collection =>
(
	is			=> 'rw',
	isa			=> Any,
	required	=> 0,
);

has dbh =>
(
	is			=> 'rw',
	isa			=> Any,
	required	=> 0,
);

our $VERSION = '0.96';

# -----------------------------------------------

sub BUILD
{
	my($self, $dbh)	= @_;

	$self -> dbh($dbh);

} # End of BUILD;

# --------------------------------------------------

sub hashes
{
	my($self, $sql) = @_;

	return $self -> collection -> hashes;

	return $self;

} # End of hashes.

# --------------------------------------------------

sub query
{
	my($self, $sql) = @_;

	$self -> collection($self -> dbh -> selectall_array($sql) );

	return $self;

} # End of query.

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