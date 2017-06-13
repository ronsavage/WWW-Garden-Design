#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

# Start block 1.
use base;
use boolean;
use Config::Tiny;
use Data::Dumper::Concise;
use Date::Simple;
use DBD::SQLite;
use DBI;
use DBIx::Admin::CreateTable;
use DBIx::Simple;
use Encode;
use File::Slurper;
use FindBin;
use Getopt::Long;
use Imager;
use Imager::Fill;
use Lingua::EN::Inflect;
use Mojolicious::Validator;
use Mojo::Base;
use Mojo::Log;
use Moo;
use Params::Classify;
use Path::Tiny;
use Pod::Usage;
use Sort::Naturally;
use strict;
use SVG::Grid;
use Text::CSV;
use Text::CSV::Encoded;
use Text::Xslate;
use Time::HiRes;
use Types::Standard;
use Unicode::Collate;
use URI::Find::Schemeless;
use utf8;
use warnings;
# End block 1.

use Test::More;

# Start block 2.
use WWW::Garden::Design; # For the version #.
# End block 2.

# ----------------------

pass('All external modules loaded');

# Start block 3.
my(@modules) = qw
(
	base
	boolean
	Config::Tiny
	Data::Dumper::Concise
	Date::Simple
	DBD::SQLite
	DBI
	DBIx::Admin::CreateTable
	DBIx::Simple
	Encode
	File::Slurper
	FindBin
	Getopt::Long
	Imager
	Imager::Fill
	Lingua::EN::Inflect
	Mojolicious::Validator
	Mojo::Base
	Mojo::Log
	Moo
	Params::Classify
	Path::Tiny
	Pod::Usage
	Sort::Naturally
	strict
	SVG::Grid
	Text::CSV
	Text::CSV::Encoded
	Text::Xslate
	Time::HiRes
	Types::Standard
	Unicode::Collate
	URI::Find::Schemeless
	utf8
	warnings
	Test::More
);
# End block 3.

# Start block 4.
diag "Testing WWW::Garden::Design V $WWW::Garden::Design::VERSION";
# End block 4.

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
