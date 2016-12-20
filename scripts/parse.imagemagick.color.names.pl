#!/usr/bin/env perl

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Getopt::Long;

use WWW::Garden::Design::Util::Import;

use Pod::Usage;

# -----------------------------------------------

my($option_parser) = Getopt::Long::Parser -> new;

my(%option);

if ($option_parser -> getoptions
(
	\%option,
	'help',
	'output_file=s',
) )
{
	pod2usage(1) if ($option{'help'});

	exit WWW::Garden::Design::Util::Import -> new(%option) -> parse_imagemagick_color_names;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

parse.imagemagick.color.names.pl - Output flowers db to CSV

=head1 SYNOPSIS

parse.imagemagick.color.names.pl [options]

	Options:
	-help
	-output_file aCSVFileName

All switches can be reduced to a single letter.

Exit value: 0.

=head1 OPTIONS

=over 4

=item o -help

Print help and exit.

=item o -output_file aCSVFileName

The name of a CSV file to write.

By default, nothing is written.

Default: ''.

=back

=cut
