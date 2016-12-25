#!/bin/bash
#
# Note: You need to install dot (http://graphviz.org/) and MarpaX::Languages::Dash to get render.pl.
# The latter is installed with shell> cpanm MarpaX::Languages::Dash.

perl ../MarpaX-Languages-Dash/scripts/render.pl	\
	-i html/Garden.Design.Software.figure.1.dash	\
	-o html/Garden.Design.Software.figure.1.svg		\
	-dot html/Garden.Design.Software.figure.1.gv

pod2html.pl -i html/Garden.Design.Software.pod -o html/Garden.Design.Software.html

cp html/*.jpg						$DR/Perl-modules/html/garden.design
cp html/Garden.Design.Software.*	$DR/Perl-modules/html/garden.design
cp html/*							$HOME/savage.net.au/Perl-modules/html/garden.design
