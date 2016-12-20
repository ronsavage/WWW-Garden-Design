#!/bin/bash

perl -Ilib scripts/drop.tables.pl
perl -Ilib scripts/create.tables.pl
perl -Ilib scripts/populate.tables.pl
