#!/bin/bash

perl -Ilib scripts/export.all.pages.pl
perl -Ilib scripts/export.icons.pl
perl -Ilib scripts/export.layouts.pl

cp -r ~/savage.net.au/Flowers* $DR/
