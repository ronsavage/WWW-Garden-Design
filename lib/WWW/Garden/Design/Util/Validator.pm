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
	$self -> add_dimension_check;

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

1;
