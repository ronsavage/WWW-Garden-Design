package WWW::Garden::Design::Util::Validator;

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Dumper::Concise; # For Dumper().

use Mojolicious::Validator;

use Moo;

use Params::Classify 'is_number';

use Types::Standard qw/Object/;

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

} # End of BUILD.

# -----------------------------------------------

sub add_attribute_range_check
{
	my($self) = @_;

	$self -> validator -> add_check
	(
		attribute_range => sub
		{
			my($validation, $name, $value, @args) = @_;

			# Return 0 for success, 1 for error!
			# Warning: The test will fail if (length($value) == 0)!

			return 1 if ($value !~ /^([^cm]+)(?:c?m){0,1}$/);

			my(@range) = split(/-/, $1);

			return 1 if ($#range > 1);		# 1-2-3 is unaccepatable.

			# A number is acceptable, so return 0!

			if ($#range == 0)
			{
				return ! is_number($range[0]);
			}
			else
			{
				return ! (is_number($range[0]) && is_number($range[1]) );
			}
		}
	);

} # End of add_attribute_range_check.

# -----------------------------------------------

sub check_attribute_range
{
	my($self, $params, $name) = @_;

	$self -> validation -> input($params);

	return (length($$params{$name}) == 0)
			|| $self
			-> validation
			-> required($name, 'trim')
			-> attribute_range
			-> is_valid;

} # End of check_attribute_range.

# -----------------------------------------------
# Warning: Returns 1 for valid!

sub check_count
{
	my($self, $hashref, $name, $count) = @_;

	return $$hashref{$name} == $count ? 1 : 0;

} # End of check_count.

# -----------------------------------------------

sub check_equal_to
{
	my($self, $params, $name, $expected) = @_;

	$self -> validation -> input($params);

	return $self
			-> validation
			-> required($name, 'trim')
			-> equal_to($expected)
			-> is_valid;

} # End of check_equal_to.

# -----------------------------------------------
# Warning: Returns 1 for valid!

sub check_key_exists
{
	my($self, $hashref, $name) = @_;

	return exists($$hashref{$name}) ? 1 : 0;

} # End of check_key_exists.

# -----------------------------------------------

sub check_member
{
	my($self, $params, $name, $set) = @_;

	$self -> validation -> input($params);

	return $self
			-> validation
			-> required($name, 'trim')
			-> in(@$set)
			-> is_valid;

} # End of check_member.

# -----------------------------------------------
# Warning: Returns 1 for valid!

sub check_natural_number
{
	my($self, $params, $name)	= @_;
	my($value)					= $$params{$name};

	return ( (length($value) == 0) || ($value !~ /^[0-9]+$/) ) ? 0 : 1;

} # End of check_natural_number.

# -----------------------------------------------

sub check_optional
{
	my($self, $params, $name) = @_;

	$self -> validation -> input($params);

	return (length($$params{$name}) == 0)
			|| $self
			-> validation
			-> optional($name)
			-> is_valid;

} # End of check_optional.

# -----------------------------------------------

sub check_required
{
	my($self, $params, $name) = @_;

	$self -> validation -> input($params);

	return $self
			-> validation
			-> required($name, 'trim')
			-> is_valid;

} # End of check_required.

# -----------------------------------------------

1;