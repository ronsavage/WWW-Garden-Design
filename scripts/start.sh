#!/bin/bash

cp /dev/null log/development.log

scripts/hypnotoad daemon -clients 2 -listen http://localhost:3008 &
