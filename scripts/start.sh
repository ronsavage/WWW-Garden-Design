#!/bin/bash

cp /dev/null log/development.log

scripts/flowers daemon -clients 2 -listen http://*:3008 &