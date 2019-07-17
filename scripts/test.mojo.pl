#!/usr/bin/env perl

use strict;
use warnings;

use WWW::Garden::Design::Database::MojoDriver;

# ----------------------------

my($driver)	= WWW::Garden::Design::Database::MojoDriver -> new;
my($sql)	= 'select * from attribute_types';

#$driver -> arrays($sql);
$driver -> hashes($sql, 'name');
