#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use File::Temp;

use Test::More;

use WWW::Garden::Design::Util::Create;

# ---------------------------------------------

eval 'use DBI';
plan skip_all => 'DBI module required for testing DB plugin' if ($@);

# The EXLOCK option is for BSD-based systems.

my($out_dir) = File::Temp -> newdir('temp.XXXX', CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);
my($file)    = File::Spec -> catfile($out_dir, 'test.sqlite');

plan skip_all => 'Temp dir is un-writable' if (! -w $out_dir);

# One last check to see if the user has set $DBI_DSN.

if (! $ENV{DBI_DSN})
{
	eval 'use DBD::SQLite';
	plan skip_all => 'DBD::SQLite required for testing DB plugin' if ($@);

	$ENV{DBI_DSN}  = 'dbi:SQLite:dbname=$file';
	$ENV{DBI_USER} = $ENV{DBI_PASS} = '';
}

my(@opts)	= ($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS});
my($dbh)	= DBI -> connect(@opts, {RaiseError => 1, PrintError => 0, AutoCommit => 1});

WWW::Garden::Design::Util::Create -> new -> drop_all_tables;
WWW::Garden::Design::Util::Create -> new -> create_all_tables;
