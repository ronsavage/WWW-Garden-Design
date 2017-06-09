package WWW::Garden::Design::Util::Filer;

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Moo;

use Text::CSV::Encoded;

use Types::Standard qw/Object/;

has csv =>
(
	default		=> sub{return Text::CSV::Encoded -> new({allow_whitespace => 1, encoding_in => 'utf-8'})},
	is			=> 'rw',
	isa			=> Object, # 'Text::CSV::Encoded'.
	required	=> 0,
);

our $VERSION = '0.95';

# -----------------------------------------------

sub read_csv_file
{
	my($self, $file_name)	= @_;
	my($io)					= IO::File -> new($file_name, 'r');

	print "Reading $file_name. \n";

	$self -> csv -> column_names($self -> csv -> getline($io) );

	return $self -> csv -> getline_hr_all($io);

} # End of read_csv_file.

# --------------------------------------------------

1;

=head1 NAME

WWW::Garden::Design::Util::Filer - Some file helpers

=head1 Synopsis

See L<WWW::Garden::Design/Synopsis>.

=head1 Description

L<WWW::Garden::Design> implements an interface to the 'flowers' database.

=head1 Distributions

See L<WWW::Garden::Design/Distributions>.

=head1 Installation

See L<WWW::Garden::Design/Installation>.

=head1 Methods

=head2 read_csv_file()

Returns a an arrayref of hashref of records.

=head1 FAQ

See L<WWW::Garden::Design/FAQ>.

=head1 Support

See L<WWW::Garden::Design/Support>.

=head1 Author

C<WWW::Garden::Design> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2017.

L<Home page|https://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2017, Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License V 2, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
