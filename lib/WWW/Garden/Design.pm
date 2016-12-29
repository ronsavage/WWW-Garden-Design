package WWW::Garden::Design;

use Mojo::Base 'Mojolicious';

use WWW::Garden::Design::Database;
use WWW::Garden::Design::Util::Config;

use Moo;

our $VERSION = '1.00';

# ------------------------------------------------
# This method will run once at server start.

sub startup
{
	my $self = shift;

	$self -> secrets(['Passchar']);

	# Log a special line to make the start of each request easy to find in the log.
	# Of course, nothing is logged by this just because the server restarted.

	$self -> hook
	(
		before_dispatch =>
		sub
		{
			$self -> app -> log -> info('-' x 30);
		}
	);

	# Stash some gobal variables.

	my($default);

	$$default{config} = WWW::Garden::Design::Util::Config -> new -> config;
	$$default{db}     = WWW::Garden::Design::Database -> new(logger => $self -> app -> log);

	$self -> defaults($default);

	# Documentation browser under '/perldoc'.

	$self -> plugin('PODRenderer');
	$self -> plugin('ServerStatus' =>
				{
					allow       => ['127.0.0.1'],
					counterfile => '/tmp/mojolicious/counter.flowers.txt',
					path        => '/server-status',
					scoreboard  => '/tmp/mojolicious',
				});
	$self -> plugin('TagHelpers');

	# Router.

	my($r) = $self -> routes;

	# Normal route to controller.

	$r -> namespaces(['WWW::Garden::Design::Controller']);

	$r -> route('/')					-> to('Initialize#homepage');
	$r -> route('/Flower')				-> to('Flower#display');
	$r -> route('/GetAttributeTypes')	-> to('GetAttributeTypes#display');
	$r -> route('/GetDetails')			-> to('GetDetails#display');
	$r -> route('/Object')				-> to('Object#display');
	$r -> route('/AuoComplete')			-> to('AutoComplete#display');
	$r -> route('/Search')				-> to('Search#display');

} # End of startup.

# ------------------------------------------------

1;

=pod

=encoding utf8

=head1 NAME

C<WWW::Garden::Design> - Flower Database, Search Engine and Garden Design

=head1 Synopsis

The Search Engine is started by the Mojolicious command scripts/start.sh:

	#!/bin/bash

	cp /dev/null log/development.log

	scripts/flowers daemon -clients 2 -listen http://*:3008 &

Which runs scripts/flowers:

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use FindBin;
	BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

	# Start command line interface for application
	require Mojolicious::Commands;
	Mojolicious::Commands->start_app('WWW::Garden::Design');

=head1 Description

C<WWW::Garden::Design> provides:

=over 4

=item o A Flower Database using CSV files

These are used for bootstrapping the system.

=item o An Import Package

This reads the CSV files and populates the Flower Database

=item o A Flower Database managed by SQLite

=item o An Export Package

This generates:

=over 4

=item o A Flower Catalog as an HTML table

This is can be embedded in any web page. Mine is L<online|https://savage.net.au/Flowers.html>.

=item o A Garden Layout as an SVG file

There is actually one (1) SVG file for each of your gardens.

See my L<front garden layout|https://savage.net.au/Flowers/front.garden.layout.html> and my
L<back garden layout|https://savage.net.au/Flowers/back.garden.layout.html>.

=item o A set of updated CSV files

For when you update the database either by the Search Engine or otherwise.

=back

=item o A Search Engine

This is a L<Mojolicious>-based program.

=back

For an introduction, see my article L<https://savage.net.au/Perl-modules/html/garden.design/Garden.Design.Software.html>.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<https://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install C<WWW::Garden::Design> as you would any C<Perl> module:

Run:

	cpanm WWW::Garden::Design

or run:

	sudo cpan WWW::Garden::Design

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/WWW-Garden-Design>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=WWW::Garden::Design>.

=head1 Author

L<WWW::Garden::Design> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2014.

My homepage: L<https://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2014, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License 2.0, a copy of which is available at:
	http://opensource.org/licenses/alphabetical.

=cut
