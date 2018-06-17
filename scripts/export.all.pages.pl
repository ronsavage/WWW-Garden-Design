#!/usr/bin/env perl

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.
use open      qw(:std :utf8); # Undeclared streams in UTF-8.

use Getopt::Long;

use WWW::Garden::Design::Export::Pg;
use WWW::Garden::Design::Export::SQLite;

use Pod::Usage;

# -------------------------------

my($db_type) = $ENV{FLOWER_DB};

if ( (! $db_type) || ($db_type !~ /^(Pg|SQLite)$/) )
{
	print "Env var FLOWER_DB must match /^(Pg|SQLite)\$/\n";
}

my($option_parser) = Getopt::Long::Parser -> new;

my(%option);

if ($option_parser -> getoptions
(
 \%option,
	'all=s',
	'help',
) )
{
	pod2usage(1) if ($option{'help'});

	if ($db_type eq 'Pg')
	{
		exit WWW::Garden::Design::Export::Pg -> new -> export_all_pages;
	}
	else
	{
		exit WWW::Garden::Design::Export::SQLite -> new -> export_all_pages;
	}
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
	-all Yes or No
	-help

All switches can be reduced to a single letter.

Exit value: 0.

=head1 OPTIONS

=item o all => Yes or No

=over 4

=item o Yes

Export everything.

=item o No

Respect property/garden/flower-level publish flag.

=back

=over 4

=item o help

Print help and exit.

=back

=cut
