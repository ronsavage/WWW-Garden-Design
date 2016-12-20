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

	exit WWW::Garden::Design::Util::Export -> new -> export_all_pages;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

export.all.pages.pl - Export a page for each flower.

=head1 SYNOPSIS

export.all.pages.pl [options]

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
