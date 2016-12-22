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
	'help',
) )
{
	pod2usage(1) if ($option{'help'});

	print WWW::Garden::Design::Util::Export -> new -> export_layout_guide;

	exit 0;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

export.layout.guide.pl - Export flowers schema/layout as a table.

=head1 SYNOPSIS

export.layout.guide.pl [options]

	Options:
	-help

All switches can be reduced to a single letter.

Exit value: 0.

=head1 OPTIONS

=over 4

=item -help

Print help and exit.

=back

=cut
