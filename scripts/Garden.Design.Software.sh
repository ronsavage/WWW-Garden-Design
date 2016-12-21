#!/bin/bash

perl ../MarpaX-Demo-StringParser/scripts/render.pl	\
	-i html/Garden.Design.Software.figure.1.dash	\
	-o html/Garden.Design.Software.figure.1.svg		\
	-dot html/Garden.Design.Software.figure.1.gv

pod2html.pl -i html/Garden.Design.Software.pod -o html/Garden.Design.Software.html

cp html/*.jpg						$DR/Perl-modules/html/garden.design
cp html/Garden.Design.Software.*	$DR/Perl-modules/html/garden.design
cp html/Garden.Design.Software.*	$HOME/savage.net.au/Perl-modules/html/garden.design
