package WWW::Garden::Design::Util::Filer;

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Dumper::Concise; # For Dumper().

use File::Slurper 'read_dir';

use FindBin;

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

sub investigate
{
	my($self) = @_;

	# Phase 1: Read all CSV files.

	my(%data);
	my($kind);

	for my $file_name (grep{/csv$/} read_dir("$FindBin::Bin/../data") )
	{
		$kind			= $file_name =~ s/\.csv//r;
		$data{$kind}	= $self -> read_csv_file("$FindBin::Bin/../data/$file_name");
	}

	# Phase 2: Convert the flowers data into a hash with the common_name as the key.

	my(%flowers);

	for my $item (@{$data{flowers} })
	{
		$flowers{$$item{common_name} } = $item;
	}

	# Phase 3: Scan all CSV data except flowers and ensure all common_names are in flowers.csv.

	my(%has_common_name) =
	(
		attributes			=> 1,
		flower_locations	=> 1,
		images				=> 1,
		notes				=> 1,
		urls				=> 1,
	);

	my($common_name);

	for $kind (sort keys %data)
	{
		next if (! $has_common_name{$kind});

		for my $record (@{$data{$kind} })
		{
			$common_name = $$record{common_name};

			if (! exists($flowers{$common_name} ) )
			{
				print "Common name $common_name in $kind.csv is not in flowers.csv. \n";
			}
		}
	}

} # End of investigate.

# -----------------------------------------------

sub read_csv_file
{
	my($self, $file_name)	= @_;
	my($io)					= IO::File -> new($file_name, 'r');

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
