package WWW::Garden::Design::Controller::Report;

use Mojo::Base 'Mojolicious::Controller';

use Date::Simple;

use Moo;

our $VERSION = '0.96';

# -----------------------------------------------

sub crosscheck
{
	my($self) = @_;

	$self -> app -> log -> debug('Report.crosscheck()');

	my($defaults)	= $self -> app -> defaults;
	my($items)		= $$defaults{db} -> crosscheck;

	$self -> stash(result_html	=> $self -> format_crosscheck($items) );
	$self -> render;

} # End of crosscheck.

# -----------------------------------------------

sub format_crosscheck
{
	my($self, $items) = @_;

	$self -> app -> log -> debug('Report.format_crosscheck(...)');

	my($html) = '';

	for my $item (@$items)
	{
		$html .= <<EOS;
<tr>
	<td>$$item{context}</td>
	<td>$$item{outcome}</td>
	<td>$$item{file}</td>
</tr>
EOS

	$self -> app -> log -> debug("context: $$item{context}. type: $$item{outcome}. file: $$item{file}");
	}

	return $html;

} # End of format_crosscheck.

# -----------------------------------------------

1;

=pod

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/WWW-Garden-Design>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=WWW::Garden::Design>.

=head1 Author

L<WWW::Garden::Design> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2014.

My homepage: L<https://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2018, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
