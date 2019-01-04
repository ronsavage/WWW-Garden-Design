#!/usr/bin/env perl

use lib 'lib';
use strict;
use warnings;

use Mojolicious::Commands;

# ------------------------

# Start command line interface for application.

Mojolicious::Commands->start_app('WWW::Garden::Design');
