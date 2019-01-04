#!/bin/bash

cp /dev/null log/development.log

perl scripts/design.pl daemon -l http://localhost:3008 &
