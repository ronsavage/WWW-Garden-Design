#!/usr/bin/env perl

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.
use open      qw(:std :utf8); # Undeclared streams in UTF-8.

use Getopt::Long;

use WWW::Garden::Design::Util::Filer;

use Mojo::Log;

use Pod::Usage;

# -------------------------------

my($log_path)		= "$ENV{HOME}/perl.modules/WWW-Garden-Design/log/development.log";
my($option_parser)	= Getopt::Long::Parser -> new;

my(%option);

if ($option_parser -> getoptions
(
 \%option,
	'help',
) )
{
	pod2usage(1) if ($option{'help'});

	exit WWW::Garden::Design::Util::Filer -> new(logger => Mojo::Log -> new(path => $log_path) ) -> investigate;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

investigate.pl - Check anything by reading all CSV files.

=head1 SYNOPSIS

investigate.pl [options]

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
