#!/usr/bin/env perl

use strict;
use warnings;

use WWW::Garden::Design::Util::Import;

# ----------------------------

WWW::Garden::Design::Util::Import -> new -> populate_all_tables;
