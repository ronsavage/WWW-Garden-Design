#!/usr/bin/env perl

use strict;
use warnings;

use WWW::Garden::Design::Util::Import::SQLite;

# ----------------------------

WWW::Garden::Design::Util::Import::SQLite -> new -> populate_all_tables;
