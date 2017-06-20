#!/usr/bin/env perl

use strict;
use warnings;

use DBI;
use DBIx::Simple;

use Test::More;

use WWW::Garden::Design::Util::Validator;

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

my($checker)	= WWW::Garden::Design::Util::Validator -> new;
my($simple)		= DBIx::Simple -> new($dbh);
my(%expected)	=
(
	attribute_types	=>   4,
	attributes		=> 664,
	colors 			=> 674,
	flowers			=> 168,
	gardens			=>   5,
	images			=> 457,
	notes			=> 761,
	properties		=>   3,
	objects			=>  28,
	urls			=> 194,
);

my($result);
my($sql, $set);

for my $table_name(qw/attribute_types attributes colors flowers gardens images notes objects urls/)
{
	$sql	= "select count(*) as count from $table_name";
	$set	= $simple -> query($sql) || die $simple -> error;
	$result	= $set -> hash;

	ok($checker -> check_count($result, 'count', $expected{$table_name}) == 1, "Table: $table_name. Records: $expected{$table_name}. Found: $$result{count}");
}

done_testing;
