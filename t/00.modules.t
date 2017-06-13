#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing these but that did not work.

use DBD::SQLite;
use DBI;
use DBIx::Admin::CreateTable;
use DBIx::Simple;
use Test::More;

use WWW::Garden::Design; # For the version #.

# ----------------------

pass('All external modules loaded');

diag "Testing WWW::Garden::Design V $WWW::Garden::Design::VERSION";

my(@modules) = qw
(
	DBD::SQLite
	DBI
	DBIx::Admin::CreateTable
	DBIx::Simple
	Test::More
);

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'};

	diag "Using $module V $ver";
}

done_testing;
