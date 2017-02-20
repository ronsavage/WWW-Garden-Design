#!/usr/bin/env perl

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Getopt::Long;

use WWW::Garden::Design::Util::Export;

use Pod::Usage;

# -------------------------------

my($option_parser) = Getopt::Long::Parser -> new;

my(%option);

if ($option_parser -> getoptions
(
 \%option,
	'export_type=i',
	'help',
	'standalone_page=i',
) )
{
	pod2usage(1) if ($option{'help'});

	$option{export_type}     = 0 if (! defined $option{export_type});
	$option{standalone_page} = 0 if (! defined $option{standalone_page});

	print WWW::Garden::Design::Util::Export -> new
		(
			export_type     => $option{export_type},
			standalone_page => $option{standalone_page},
		) -> as_html;

	exit 0;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

export.as.html.pl - Export flowers as a table or a whole page.

=head1 SYNOPSIS

export.as.html.pl [options]

	Options:
	-export_type
	-help
	-standalone_page

All switches can be reduced to a single letter.

Exit value: 0.

=head1 OPTIONS

=over 4

=item o export_type => $integer

Values for the C<export_type> parameter:

=over 4

=item o 0

	'#'
	'Native'
	'Scientific name'
	'Common name'
	'Aliases'
	'Thumbnail <span class = "index">(clickable)</span>'

=item o 1

	'#'
	'Native'
	'Scientific name'
	'Common name'
	'Aliases'
	'Thumbnail <span class = "index">(clickable)</span>'

=back

Default: 0.

=item o help

Print help and exit.

=item o standalone_page => $integer

Output a standalone web page.

If omitted (the default) a HTML table is output for incorporation into a web page.

Default: 0.

=back

=cut
