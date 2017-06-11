#!/usr/bin/env perl

use strict;
use warnings;

use DBI;
use DBIx::Simple;

use Test::More;

# ---------------------------------------------

my($test_database)	= 'data/flowers.sqlite';
my($config)			=
{
	dsn				=> "dbi:SQLite:dbname=$test_database",
	sqlite_unicode	=> 1,
};
my($attr) =
{
	AutoCommit => defined($$config{AutoCommit}) ? $$config{AutoCommit} : 1,
	RaiseError => defined($$config{RaiseError}) ? $$config{RaiseError} : 1,
};
$$attr{sqlite_unicode} = 1 if ( ($$config{dsn} =~ /SQLite/i) && $$config{sqlite_unicode});

note("Testing $test_database");

my($dbh) = DBI -> connect($$config{dsn}, $$config{username}, $$config{password}, $attr);

$dbh -> do('PRAGMA foreign_keys = ON') if ($$config{dsn} =~ /SQLite/i);

my($simple)		= DBIx::Simple -> new($dbh);
my(%expected)	=
(
	attribute_types	=>   4,
	attributes		=> 628,
	colors 			=> 674,
	flowers			=> 157,
	gardens			=>   2,
	images			=> 395,
	notes			=> 662,
	objects			=>  28,
	urls			=> 174,
);

my($result);
my($sql, $set);

for my $table_name(qw/attribute_types attributes colors flowers gardens images notes objects urls/)
{
	$sql	= "select count(*) as count from $table_name";
	$set	= $simple -> query($sql) || die $simple -> error;
	$result	= $set -> hash;

	ok($$result{count} == $expected{$table_name}, "Table: $table_name. Records: $expected{$table_name}. Found: $$result{count}");
}

done_testing;