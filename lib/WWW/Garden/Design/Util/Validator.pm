package WWW::Garden::Design::Util::Validator;

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Dumper::Concise; # For Dumper().

use Mojolicious::Validator;

use Moo;

use Params::Classify 'is_number';

use Types::Standard qw/Object/;

use URI::Find::Schemeless;

has url_finder =>
(
	default		=> sub{return URI::Find::Schemeless -> new(sub{my($url, $text) = @_; return $url})},
	is			=> 'ro',
	isa			=> Object,
	required	=> 0,
);

has validation =>
(
	is			=> 'rw',
	isa			=> Object,
	required	=> 0,
);

has validator =>
(
	default		=> sub{return Mojolicious::Validator -> new},
	is			=> 'ro',
	isa			=> Object,
	required	=> 0,
);

our $VERSION = '0.95';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

	$self -> validation($self -> validator -> validation);
	$self -> add_dimension_check;
	$self -> add_url_check;

} # End of BUILD.

# -----------------------------------------------

sub add_dimension_check
{
	my($self) = @_;

	$self -> validator -> add_check
	(
		dimension => sub
		{
			my($validation, $topic, $value, @args) = @_;

			# Return 0 for success, 1 for error!
			# Warning: The test will fail if (length($value) == 0)!

			my($args) = join('|', @args);

			return 1 if ($value !~ /^([0-9.]+)(-[0-9.]+)?\s*(?:$args){0,1}$/);

			my($one, $two)	= ($1, $2 || '');
			$two			= substr($two, 1) if (substr($two, 0, 1) eq '-');

			if (length($two) == 0)
			{
				return ! is_number($one);
			}
			else
			{
				return ! (is_number($one) && is_number($two) );
			}
		}
	);

} # End of add_dimension_check.

# -----------------------------------------------

sub add_url_check
{
	my($self) = @_;

	$self -> validator -> add_check
	(
		url => sub
		{
			my($validation, $topic, $value, @args)	= @_;
			my($count)								= $self -> url_finder -> find(\$value);

			# Return 0 for success, 1 for error!

			return ($count == 1) ? 0 : 1;
		}
	);

} # End of add_url_check.

# -----------------------------------------------
# Warning: Returns 1 for valid!

sub check_count
{
	my($self, $params, $topic, $count) = @_;

	return $$params{$topic} == $count ? 1 : 0;

} # End of check_count.

# -----------------------------------------------

sub check_dimension
{
	my($self, $params, $topic, $units) = @_;

	$self -> validation -> input($params);

	return (length($$params{$topic}) == 0)
			|| $self
			-> validation
			-> required($topic, 'trim')
			-> dimension(@$units)
			-> is_valid;

} # End of check_dimension.

# -----------------------------------------------

sub check_equal_to
{
	my($self, $params, $topic, $expected) = @_;

	$self -> validation -> input($params);

	return $self
			-> validation
			-> required($topic, 'trim')
			-> equal_to($expected)
			-> is_valid;

} # End of check_equal_to.

# -----------------------------------------------
# Warning: Returns 1 for valid!

sub check_key_exists
{
	my($self, $params, $topic) = @_;

	return exists($$params{$topic}) ? 1 : 0;

} # End of check_key_exists.

# -----------------------------------------------

sub check_member
{
	my($self, $params, $topic, $set) = @_;

	$self -> validation -> input($params);

	return $self
			-> validation
			-> required($topic, 'trim')
			-> in(@$set)
			-> is_valid;

} # End of check_member.

# -----------------------------------------------
# Warning: Returns 1 for valid!

sub check_natural_number
{
	my($self, $params, $topic)	= @_;
	my($value)					= $$params{$topic};

	return ( (length($value) == 0) || ($value !~ /^[0-9]+$/) ) ? 0 : 1;

} # End of check_natural_number.

# -----------------------------------------------

sub check_optional
{
	my($self, $params, $topic) = @_;

	$self -> validation -> input($params);

	return (length($$params{$topic}) == 0)
			|| $self
			-> validation
			-> optional($topic)
			-> is_valid;

} # End of check_optional.

# -----------------------------------------------

sub check_required
{
	my($self, $params, $topic) = @_;

	$self -> validation -> input($params);

	return $self
			-> validation
			-> required($topic, 'trim')
			-> is_valid;

} # End of check_required.

# -----------------------------------------------

sub check_url
{
	my($self, $params, $topic) = @_;

	$self -> validation -> input($params);

	return (length($$params{$topic}) == 0)
			|| $self
			-> validation
			-> required($topic, 'trim')
			-> url
			-> is_valid;

} # End of check_url.

# -----------------------------------------------

1;

=pod

=head1 NAME

C<WWW::Garden::Design::Util::Validator> - A very convenient wrapper around Mojolicious::Validator

=head1 Synopsis

This program ships as scripts/synopsis.pl:

	#!/usr/bin/env perl

	use lib 'lib';
	use strict;
	use warnings;

	use WWW::Garden::Design::Util::Validator;

	# ------------------------------------------------

	my(%count)		= (pass => 0, total => 0);
	my($checker)	= WWW::Garden::Design::Util::Validator -> new;

	$checker -> add_dimension_check;

	my(@data) =
	(
		{height => ''},				# Pass.
		{height => '1'},			# Fail. No unit.
		{height => '1cm'},			# Pass.
		{height => '1 cm'},			# Pass.
		{height => '1m'},			# Pass.
		{height	=> '40-70.5cm'},	# Pass.
		{height	=> '1.5-2m'},		# Pass.
		{height => 'z1'},			# Pass.
	);

	my($expected);
	my($infix);

	for my $params (@data)
	{
		$count{total}++;

		$count{pass}++ if ($checker -> check_dimension($params, 'height', ['cm', 'm']) == 1);
	}

	$count{total}++;

	$count{pass}++ if ($checker -> check_optional({x => ''}, 'x') == 1);

	print "Test counts: \n", join("\n", map{"$_: $count{$_}"} sort keys %count), "\n";

This is the printout of synopsis.pl:

	Test counts:
	pass: 8
	total: 9

See also t/t.pl.

=head1 Description

C<WWW::Garden::Design::Util::Validator> is a wrapper around L<Mojolicious::Validator> which
provides a suite of convenience methods for validation.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install C<WWW::Garden::Design::Util::Validator> as you would any C<Perl> module:

Run:

	cpanm WWW::Garden::Design::Util::Validator

or run:

	sudo cpan Text::Balanced::Marpa

or unpack the distro, and then run:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

C<new()> is called as C<< my($parser) = WWW::Garden::Design::Util::Validator -> new >>.

It returns a new object of type C<WWW::Garden::Design::Util::Validator>.

C<new() does not take any parameters.

=head1 Methods

=head2 add_dimension_check()

Called in BEGIN(). The check itself is called C<dimension>.

=head2 add_url_check()

Called in BEGIN(). The check itself is called C<url>.

This method uses L<URI::Find::Schemeless>.

=head2 check_count($params, $topic, $count)

=head2 check_dimension($params, $topic, $units)

=head2 check_equal_to($params, $topic, $expected)

=head2 check_key_exists()

=head2 check_member($params, $topic, $set)

=head2 check_natural_number($params, $topic)

=head2 check_optional($params, $topic)

=head2 check_required($params, $topic)

=head2 check_url($params, $topic)

=head2 new()

=head2 url_finder()

Returns an object of type L<URI::Find::Schemeless>.

=head2 validation()

Returns an object of type L<Mojolicious::Validator::Validation>

=head2 validator()

Returns an object of type L<Mojolicious::Validator>

=head1 FAQ

=head1 See Also

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/WWW::Garden::Design::Util::Validator>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=WWW::Garden::Design::Util::Validator>.

=head1 Author

L<WWW::Garden::Design::Util::Validator> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2017.

My homepage: L<http://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2017, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/.

=cut
