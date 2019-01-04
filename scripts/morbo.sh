#!/bin/bash

cp /dev/null log/development.log

morbo -l http://localhost:3008 scripts/design.pl &
