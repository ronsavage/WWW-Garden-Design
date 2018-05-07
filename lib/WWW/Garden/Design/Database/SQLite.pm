package WWW::Garden::Design::Database::SQLite;

use parent WWW::Garden::Design::Database;
use boolean;
use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use DBI;

use DBIx::Simple;

use FindBin;

use Imager;
use Imager::Fill;

use Lingua::EN::Inflect qw/inflect PL_N/; # PL_N: plural of a singular noun.

use Moo;

use Text::CSV::Encoded;

use Types::Standard qw/Object/;

use Unicode::Collate;

has dbh =>
(
	is			=> 'rw',
	isa			=> Object,
	required	=> 0,
);

has simple =>
(
	is       => 'rw',
	isa      => Object,
	required => 0,
);

our $VERSION = '0.96';

# -----------------------------------------------

sub BUILD
{
	my($self)		= @_;
	my($config)		= $self -> config;
	my(%attributes)	=
	(
		AutoCommit 			=> $$config{AutoCommit},
		mysql_enable_utf8	=> $$config{mysql_enable_utf8},	#Ignored if not using MySQL.
		RaiseError 			=> $$config{RaiseError},
		sqlite_unicode		=> $$config{sqlite_unicode},	#Ignored if not using SQLite.
	);

	$self -> dbh(DBI -> connect($$config{dsn}, $$config{username}, $$config{password}, \%attributes) );
	$self -> dbh -> do('PRAGMA foreign_keys = ON') if ($$config{dsn} =~ /SQLite/i);

	$self -> simple(DBIx::Simple -> new($self -> dbh) );

}	# End of BUILD.

# -----------------------------------------------

sub insert_hashref
{
	my($self, $table_name, $hashref) = @_;

	$self -> simple -> insert($table_name, {map{($_ => $$hashref{$_})} keys %$hashref})
		|| die $self -> simple -> error;

	return $self -> simple -> last_insert_id(undef, undef, $table_name, undef);

} # End of insert_hashref.

# --------------------------------------------------

sub read_table
{
	my($self, $table_name)	= @_;
	my($sql)				= "select * from $table_name";
	my($set)				= $self -> simple -> query($sql) || die $self -> db -> simple -> error;

	# Return an arrayref of hashrefs.

	return [$set -> hashes];

} # End of read_table.

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

Australian copyright (c) 2013, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
