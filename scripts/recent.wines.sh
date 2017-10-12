FILE=$DR/recent.wines.html

rm -rf $FILE

psql -U local -d wines -f scripts/recent.wines.sql -H > $FILE

echo Output to $FILE
