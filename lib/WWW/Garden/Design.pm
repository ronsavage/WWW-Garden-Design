package WWW::Garden::Design;

use Mojo::Base 'Mojolicious';

use WWW::Garden::Design::Database;
use WWW::Garden::Design::Util::Config;
use WWW::Garden::Design::Util::ValidateForm;

use Moo;

use utf8;

our $VERSION = '0.95';

# -----------------------------------------------

sub build_attribute_ids
{
	my($self, $kind, $attribute_type_fields, $attribute_type_names) = @_;

	my($id);
	my($name);

	return
	[
		map
		{
			$name = $$attribute_type_names[$_];
			[
				map
				{
					$id = "${kind}_${name}_$_" =~ s/ /_/gr;
					$id	=~ s/-/_/g;

					$id;
				} @{$$attribute_type_fields{$name} }
			]
		} 0 .. $#$attribute_type_names
	];

} # End of build_attribute_ids.

# -----------------------------------------------

sub build_attribute_type_fields
{
	my($self, $attribute_types_table) = @_;

	my(%attribute_type_fields);

	for (sort{$$a{sequence} <=> $$b{sequence} } @$attribute_types_table)
	{
		$attribute_type_fields{$$_{name} } = [split(/\s*,\s+/, $$_{range})];
	}

	return \%attribute_type_fields;

} # End of build_attribute_type_fields.

# -----------------------------------------------

sub build_attribute_type_names
{
	my($self, $attribute_types_table) = @_;

	my(@fields);
	my($name);

	return [map{$$_{name} } sort{$$a{sequence} <=> $$b{sequence} } @$attribute_types_table];

} # End of build_attribute_type_names.

# ------------------------------------------------
# This method will run once at server start.

sub startup
{
	my $self = shift;

	$self -> secrets(['757d76331dc264f21ae97b861189bd9d8aa74647']);

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

	# Stash some gobal variables.

	my($defaults);

	$$defaults{config}					= WWW::Garden::Design::Util::Config -> new -> config;
	$$defaults{db}						= WWW::Garden::Design::Database -> new(logger => $self -> app -> log);
	$$defaults{constants_table}			= $$defaults{db} -> read_constants_table; # Warning: Not read_table('constants').
	$$defaults{attributes_table}		= $$defaults{db} -> read_table('attributes');
	$$defaults{attribute_types_table}	= $$defaults{db} -> read_table('attribute_types');
	$$defaults{attribute_type_names}	= $self -> build_attribute_type_names($$defaults{attribute_types_table});
	$$defaults{attribute_type_fields}	= $self -> build_attribute_type_fields($$defaults{attribute_types_table});
	$$defaults{attribute_attribute_ids}	= $self -> build_attribute_ids('attribute', $$defaults{attribute_type_fields}, $$defaults{attribute_type_names});
	$$defaults{joiner}					= '«»'; # Must match joiner in homepage.html.ep.
	$$defaults{search_attribute_ids}	= $self -> build_attribute_ids('search', $$defaults{attribute_type_fields}, $$defaults{attribute_type_names});

	$self -> defaults($defaults);

	# Router.

	my($r) = $self -> routes;

	$r -> namespaces(['WWW::Garden::Design::Controller']);

	$r -> route('/')							-> to('Initialize#homepage');
	$r -> route('/AddFlower')					-> to('AddFlower#save');
	$r -> route('/AddGarden')					-> to('AddGarden#save');
	$r -> route('/AddObject')					-> to('AddObject#save');
	$r -> route('/AddProperty')					-> to('AddProperty#save');
	$r -> route('/AutoComplete')				-> to('AutoComplete#display');
	$r -> route('/Design')						-> to('Design#save');
	$r -> route('/GetFlowerDetails')			-> to('GetFlowerDetails#display');
	$r -> route('/GetTable/attribute_types')	-> to('GetTable#attribute_types');
	$r -> route('/GetTable/design_flower')		-> to('GetTable#design_flower');
	$r -> route('/GetTable/design_object')		-> to('GetTable#design_object');
	$r -> route('/GetTable/gardens')			-> to('GetTable#gardens');
	$r -> route('/GetTable/objects')			-> to('GetTable#objects');
	$r -> route('/GetTable/properties')			-> to('GetTable#properties');
	$r -> route('/Search')						-> to('Search#display');

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

An L<article|https://savage.net.au/Flowers/html/Garden.Design.Software.html> about the package is
on-line.

C<WWW::Garden::Design> provides:

=over 4

=item o A Flower Database stored in CSV files

These are used for bootstrapping the system into the SQLite database (below).

=item o An Import Package

This reads the CSV files and populates the Flower Database.

=item o A Flower Database managed by SQLite

For testing, a copy ships in data/flowers.sqlite.

=item o An Export Package

There are a number of simple Perl scripts involved, and some bash scripts to tie them together.

They generate:

=over 4

=item o A web page for every flower

These are pointed to be clickable thumbnails on the 'Flower Catalog' (next) and the 'Garden Layouts'
(below).

These pages consist of a set of details per flower:

=over 4

=item o Scientific name

=item o Common name

=item o Aliases

=item o Attributes

Details (so far) for: native, habit, edibleness and sub tolerance.

=item o A set of images

=item o A set of notes

=item o A set of URLs

=back

=item o The 'Flower Catalog' as an HTML table

This can be generated as a stand-alone page, or as a HTML table to be embedded in any web page.
Mine is L<online|https://savage.net.au/Flowers.html#the_flower_catalog>.

Each row in the table displays:

=over 4

=item o A native (to Australia) flag (Yes or No)

=item o The Scientific name

=item o The Common name

Actually, I've fiddled some of these to make flowers which have significantly different scientific
names end up on successive rows of the table. Likewise, flowers with very similar names are forced
to appear together in the table.

=item o A list of the flower's aliases

Search for 'pansy' to see a ridiculous list as a sample.

=item o A clickable thumbnail

Clicking opens up, in a new browser tab, a page dedicated to the flower whose thumbnail was clciked.

=back

=item o 'Garden Layouts' as SVG files

One SVG file is created for each of your gardens.

See my L<front garden layout|https://savage.net.au/Flowers/front.garden.layout.html> and
L<back garden layout|https://savage.net.au/Flowers/back.garden.layout.html>.

=item o A set of updated CSV files

For when you update the database either via the Search Engine or otherwise.

=back

=item o A Search Engine

This is a L<Mojolicious>-based program.

=back

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

Australian copyright (c) 2013, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
