#!/usr/bin/env perl

use strict;
use warnings;

use DBI;
use DBIx::Simple;

use Test::More;

use MojoX::Validate::Util;

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

my($checker)	= MojoX::Validate::Util -> new;
my($simple)		= DBIx::Simple -> new($dbh);
my(%expected)	=
(	# We omit the log table since we don't know how many records it has at any time.
	attribute_types		=>    5,
	attributes			=> 1015,
	constants			=>   31,
	feature_locations	=>  701,
	features			=>   38,
	flower_locations	=>  257,
	flowers				=>  203,
	gardens				=>    2,
	images				=>  549,
	notes				=>  129,
	properties			=>    2,
	urls				=>  216,
);

my($result);
my($sql, $set);

for my $table_name (sort keys %expected)
{
	$sql	= "select count(*) as count from $table_name";
	$set	= $simple -> query($sql) || die $simple -> error;
	$result	= $set -> hash;

	ok($checker -> check_number($result, 'count', $expected{$table_name}) == 1, "Table: $table_name. Records: $expected{$table_name}. Found: $$result{count}");
}

done_testing;
