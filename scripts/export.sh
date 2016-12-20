#!/bin/bash

perl -Ilib scripts/export.all.pages.pl
perl -Ilib scripts/export.icons.pl
perl -Ilib scripts/export.layouts.pl

cp html/*.svg html/*.html ~/savage.net.au/Flowers
cp -r ~/savage.net.au/Flowers* $DR/
