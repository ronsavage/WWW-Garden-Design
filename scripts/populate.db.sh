#!/bin/bash

if [ "$FLOWER_DB" == "Pg" ]; then
	echo Deleting, creating and populating the Pg flowers database
else
	echo Deleting, creating and populating the SQLite flowers database
fi

perl -Ilib scripts/drop.tables.pl
perl -Ilib scripts/create.tables.pl

if [ "$FLOWER_DB" == "Pg" ]; then
	time perl -Ilib scripts/populate.pg.tables.pl
else
#	time perl -Ilib scripts/populate.sqlite.tables.pl
	echo Skip populate
fi
