#!/usr/bin/env perl

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.
use open      qw(:std :utf8); # Undeclared streams in UTF-8.

use Getopt::Long;

use WWW::Garden::Design::Database;

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

	exit WWW::Garden::Design::Database -> new(logger => Mojo::Log -> new(path => $log_path) ) -> crosscheck;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

crosscheck.pl - Check Latin names against image file names.

=head1 SYNOPSIS

crosscheck.pl [options]

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
