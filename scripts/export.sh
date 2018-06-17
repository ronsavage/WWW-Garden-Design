#!/bin/bash

if [ "$FLOWER_DB" == "Pg" ]; then
	echo Exporting the Pg flowers database
else
	echo Exporting the SQLite flowers database
fi

if [ "$FLOWER_DB" == "Pg" ]; then
	time perl -Ilib scripts/export.all.pg.pages.pl
	time perl -Ilib scripts/export.pg.features.pl
	time perl -Ilib scripts/export.pg.layouts.pl
else
	time perl -Ilib scripts/export.all.sqlite.pages.pl
	time perl -Ilib scripts/export.sqlite.features.pl
	time perl -Ilib scripts/export.sqlite.layouts.pl
fi

cp -r ~/savage.net.au/Flowers* $DR/
