package WWW::Garden::Design::Controller::Report;

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper::Concise; # For Dumper().

use Date::Simple;

use Moo;

our $VERSION = '0.96';

# -----------------------------------------------

sub activity
{
	my($self) = @_;

	$self -> app -> log -> debug('Report.activity()');

	my($defaults)	= $self -> app -> defaults;
	my($items)		= $$defaults{db} -> activity;

	$self -> stash(result_html	=> $self -> format_activity($items) );
	$self -> render;

} # End of activity.

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

sub format_activity
{
	my($self, $items) = @_;

	$self -> app -> log -> debug('Report.format_activity(...)');

	my($html) = '';

	for my $item (@$items)
	{
		$html .= <<EOS;
<tr>
	<td>$$item{timestamp}</td>
	<td>$$item{name}</td>
	<td>$$item{context}</td>
	<td>$$item{note}</td>
	<td>$$item{outcome}</td>
	<td>$$item{file_name}</td>
</tr>
EOS
	}

	return $html;

} # End of format_activity.

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
	}

	return $html;

} # End of format_crosscheck.

# -----------------------------------------------

sub format_missing_attributes
{
	my($self, $items) = @_;

	$self -> app -> log -> debug('Report.format_missing_attributes(...)');

	my($html) = '';

	for my $item (@$items)
	{
		$html .= <<EOS;
<tr>
	<td>$$item{scientific_name}</td>
	<td>$$item{common_name}</td>
</tr>
EOS
	}

	return $html;

} # End of format_missing_attributes.

# -----------------------------------------------

sub format_similarities
{
	my($self, $items) = @_;

	$self -> app -> log -> debug('Report.format_similarities(...)');

	my($html) = '';

	for my $item (@$items)
	{
		$html .= <<EOS;
<tr>
	<td>$$item{scientific_name}</td>
	<td>$$item{common_name}</td>
</tr>
EOS
	}

	return $html;

} # End of format_similarities.

# -----------------------------------------------

sub missing_attributes
{
	my($self) = @_;

	$self -> app -> log -> debug('Report.missing_attributes()');

	my($defaults)	= $self -> app -> defaults;
	my($items)		= $$defaults{db} -> missing_attributes;

	$self -> stash(result_html	=> $self -> format_missing_attributes($items) );
	$self -> render;

} # End of missing_attributes.

# -----------------------------------------------

sub pig_latin
{
	my($self) = @_;

	$self -> app -> log -> debug('Report.pig_latin()');

	my($defaults)		= $self -> app -> defaults;
	my($db)				= $$defaults{db};
	my($pig_latin_name)	= $db -> trim($self -> param('pig_latin_name') );
	my($pig_latin)		= $db -> convert2pig_latin($pig_latin_name);

	$self -> stash(result => $pig_latin);
	$self -> render;

} # End of pig_latin.

# -----------------------------------------------
# This code could compare each scientific name with all others,
# but I decided to retain the decision of allowing the user to choose.

sub similarities
{
	my($self) = @_;

	$self -> app -> log -> debug('Report.similarities()');

	my($defaults)		= $self -> app -> defaults;
	my($db)				= $$defaults{db};
	my($target)			= $db -> trim($self -> param('similarities_name') || '');
	my($similarities)		= $db -> find_similarities($target);

	$self -> stash(result_html => $self -> format_similarities($similarities) );
	$self -> render;

} # End of similarities.

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
