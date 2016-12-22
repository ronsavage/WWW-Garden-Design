package WWW::Garden::Design::Util::Config;

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Config::Tiny;

use Moo;

use Path::Tiny; # For path().

use Types::Standard qw/HashRef Str/;

has config =>
(
	default  => sub{return {} },
	is       => 'rw',
	isa      => HashRef,
	required => 1,
);

has config_name =>
(
	default  => sub{return 'www.garden.design.conf'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has config_path =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has config_set =>
(
	default  => sub{return {} },
	is       => 'rw',
	isa      => HashRef,
	required => 0,
);

our $VERSION = '1.00';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;
	my($path) = "$ENV{HOME}/perl.modules/WWW-Garden-Design/config/" . $self -> config_name;

	$self -> config($self -> _init_config($path) );

	my($config) = $self -> config;

	$self -> config_set
	({
		cell_width			=> $$config{cell_width},
		cell_height			=> $$config{cell_height},
		flower_dir			=> "$$config{homepage_dir}$$config{flower_url}",
		flower_url			=> "$$config{public_homepage_url}$$config{flower_url}",
		homepage_dir		=> $$config{homepage_dir},
		icon_dir			=> "$$config{homepage_dir}$$config{icon_url}",
		icon_url			=> $$config{icon_url},
		image_url			=> "$$config{public_homepage_url}$$config{image_url}",
		image_dir			=> "$$config{homepage_dir}$$config{image_url}",
		local_homepage_url	=> $$config{local_homepage_url},
		public_homepage_url	=> $$config{public_homepage_url},
		template_path		=> $$config{template_path},
		x_offset			=> $$config{x_offset},
		y_offset			=> $$config{y_offset},
	});

} # End of BUILD.

# -----------------------------------------------

sub _init_config
{
	my($self, $path) = @_;

	$self -> config_path($path);

	# Check [global].

	my($config) = Config::Tiny -> read($path);

	die 'Error: ' . Config::Tiny -> errstr . "\n" if (Config::Tiny -> errstr);

	my($section);

	for my $i (1 .. 2)
	{
		$section = $i == 1 ? 'global' : $$config{$section}{host};

		die "Error: Config file '$path' does not contain the section [$section]\n" if (! $$config{$section});
	}

	return $$config{$section};

}	# End of _init_config.

# --------------------------------------------------

1;

=head1 NAME

WWW::Garden::Design::Util::Config - Manage the flowers database

=head1 Synopsis

See L<WWW::Garden::Design/Synopsis>.

See also scripts/copy.config.pl.

=head1 Description

L<WWW::Garden::Design> implements an interface to the 'flowers' database.

=head1 Distributions

See L<WWW::Garden::Design/Distributions>.

=head1 Installation

See L<WWW::Garden::Design/Installation>.

=head1 Methods

=head2 config()

Returns a hashref of options read from C<config/www.garden.design.conf>.

=head2 config_name()

Returns a string with the value 'www.garden.design.conf'.

=head2 config_path()

Returns a string holding the path to the config file.

=head1 FAQ

See L<WWW::Garden::Design/FAQ>.

=head1 Support

See L<WWW::Garden::Design/Support>.

=head1 Author

C<WWW::Garden::Design> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2013.

L<Home page|http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2013, Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License V 2, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
