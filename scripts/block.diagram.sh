#!/bin/bash

perl ../MarpaX-Demo-StringParser/scripts/render.pl \
-i html/block.diagram.dash -o html/block.diagram.svg -dot html/block.diagram.gv

cp html/block.diagram.* $DR/Perl-modules/html/garden.design
cp html/block.diagram.* $HOME/savage.net.au/Perl-modules/html/garden.design
