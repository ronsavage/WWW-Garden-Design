package WWW::Garden::Design::Util::ValidateForm;

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Dumper::Concise; # For Dumper().

use MojoX::Validate::Util;

use Moo;

use Types::Standard qw/Object/;

has validator =>
(
	default		=> sub{return MojoX::Validate::Util -> new},
	is			=> 'ro',
	isa			=> Object,
	required	=> 0,
);

our $VERSION = '0.96';

# -----------------------------------------------

sub clean_params
{
	my($self, $controller) = @_;
	my($params)	= $controller -> req -> params -> to_hash;
	my($hash)	= {};

	my($key);
	my($value);

	for my $name (keys %$params)
	{
		$key			= $self -> trim($name);
		$value			= $self -> trim($$params{$name});
		$$hash{$key}	= $value;
	}

	return $hash;

} # End of clean_params.

# -----------------------------------------------

sub design_details
{
	my($self, $controller, $defaults) = @_;
	my($app)			= $controller -> app;
	my($joiner)			= $$defaults{joiner};
	my($params) 		= $controller -> req -> params -> to_hash;
	$$params{errors}	= {};
	$$params{message}	= '';
	$$params{success}	= 'No';

	$app -> log -> debug("design_details: $_ => $$params{$_}") for sort keys %$params;

	# %errors is declared at this level so various methods can store into it.

	my(%errors);

	$self -> process_design_property($app, $defaults, \%errors, $joiner, $params);

###############################
	$$params{success} = 'Yes'; # TODO.
###############################

	return $params;

} # End of design_details.

# -----------------------------------------------

sub flower_details
{
	my($self, $controller, $defaults) = @_;
	my($app)			= $controller -> app;
	my($joiner)			= $$defaults{joiner};
	my($params) 		= $self -> clean_params($controller);
	$$params{errors}	= {};
	$$params{message}	= '';
	$$params{success}	= 'No';

	$app -> log -> debug("flower_details: $_ => $$params{$_}") for sort keys %$params;

	# %errors is declared at this level so various methods can store into it.

	my(%errors);

	$self -> validator -> check_required($params, 'common_name');
	$self -> validator -> check_required($params, 'scientific_name');

	$self -> validator -> check_optional($params, 'aliases');
	$self -> validator -> check_optional($params, 'notes');
	$self -> validator -> check_member($params, 'publish', ['Yes', 'No']);

	$self -> process_flower_attributes($app, $defaults, \%errors, $joiner, $params);
	$self -> process_flower_dimensions($app, $defaults, \%errors, $params);
	$self -> process_flower_images($app, $defaults, \%errors, $joiner, $params);
	$self -> process_flower_urls($app, $defaults, \%errors, $joiner, $params);

	my(@args, $args);
	my($result);
	my($suffix);
	my($test);

	# Warning: Inside this loop, don't use $$params{$name} because of cases like $$params{url_list},
	# which splits into url_1, url_2, etc. Here, $name assumes these latter values, which in turn
	# means $$params{url_list} is defined but $$params{url_1} etc are all undef!

	for my $name (@{$self -> validator -> validation -> failed})
	{
		($test, $result, @args)	= @{$self -> validator -> validation -> error($name)};
		$args					= ($#args >= 0) ? join(', ', @args) : '';
		$errors{$name}			= [$$params{$name}, $test, $args];
	}

	if (scalar keys %errors == 0)
	{
		$$params{message}	= 'All fields were validated successfully';
		$$params{success}	= 'Yes';
	}
	else
	{
		$$params{errors}	= \%errors;
		$$params{message}	= 'These fields failed validation';
	}

	return $params;

} # End of flower_details.

# -----------------------------------------------

sub process_design_property
{
	my($self, $app, $defaults, $errors, $joiner, $params) = @_;

	$app -> log -> debug('ValidateForm.process_design_property(...)');

	for my $index_name (qw/garden_index property_index/)
	{
		$self -> validator -> check_ascii_digits($params, $index_name);
	}

	for my $param_name (qw/garden_name property_name/)
	{
		$self -> validator -> check_required($params, $param_name);
	}

} # End of process_design_property.

# -----------------------------------------------

sub process_flower_attributes
{
	my($self, $app, $defaults, $errors, $joiner, $params) = @_;
	my($attribute_list)	= $$params{attribute_list};
	my(@attributes)		= map{$self -> trim($_)} split(/$joiner/, $attribute_list);
	my($attributes)		= {};

	$app -> log -> debug('ValidateForm.process_flower_attributes(...)');

	my($name);

	for (my($i) = 0; $i < $#attributes; $i += 2)
	{
		$name				= $attributes[$i] =~ s/_/ /gr;
		$$attributes{$name}	= [] if (! $$attributes{$name});

		push @{$$attributes{$name} }, $attributes[$i + 1];
	}

	my($count) = 0;

	my($field);
	my($key);
	my($result);
	my($validated);

	for $name (keys %$attributes)
	{
		$count++;

		# 1: Test the name of the attribute.

		$key	= "attribute_$name";
		$result	= $self -> validator -> check_member({$key => $name}, $key, $$defaults{attribute_type_names});

		if ($result != 1)
		{
			$$errors{"attribute_$count"} = ['Name', $name, 'Unknown'];

			next;
		}

		# 2: If that test worked, test all values of the attribute.

		$validated = $self -> validator -> validation -> output;

		if (exists $$validated{$key})
		{
			for $field (@{$$attributes{$name} })
			{
				$key	= "attribute_${name}_$field";
				$result	= $self -> validator -> check_member({$key => $field}, $key, $$defaults{attribute_type_fields}{$name});

				if ($result != 1)
				{
					$$errors{"attribute_$count"} = ['Value', $field, 'Unexpected'];
				}
				else
				{
					$$params{$key} = $field;
				}
			}
		}
	}

} # End of process_flower_attributes.

# -----------------------------------------------

sub process_flower_dimensions
{
	my($self, $app, $defaults, $errors, $params) = @_;
	my($height)	= $$params{height}; # Already trimmed.
	my($width)	= $$params{width};

	$app -> log -> debug("ValidateForm.process_flower_dimensions(height: $height, width: $width)");
	$self -> validator -> check_dimension({height => $height}, 'height', ['cm', 'm']);
	$self -> validator -> check_dimension({width => $width}, 'width', ['cm', 'm']);

} # End of process_flower_dimensions.

# -----------------------------------------------

sub process_flower_images
{
	my($self, $app, $defaults, $errors, $joiner, $params) = @_;
	my($image_list)	= $$params{image_list};
	my(@images)		= map{defined($_) ? $self -> trim($_) : ''} split(/$joiner/, $image_list);

	$app -> log -> debug('ValidateForm.process_flower_images(...)');

	# I'm currently accepting duplicate file names and duplicate descriptions.
	# Also, accept empty image description without generating an error msg.
	#
	# Expected format of @images:
	# o [$i]: A string id of the form 'image_\d+'.
	# o [$i + 1]: The image's name.
	# o [$i + 2]: The image's description.

	my(@id_length)		= (7, 8); # (Min, Max).
	my($id_message)		= "$id_length[0] .. $id_length[1] chars";
	my($prefix_length)	= 20;
	my(@image_length)	= (4, 250); # (Min, Max).
	my($image_message)	= "$image_length[0] .. $image_length[1] chars";

	my($id, $image_length);
	my($key);

	for (my($i) = 0; $i < $#images; $i += 3)
	{
		$image_length = length($images[$i]);

		# Ignore empty id without generating an error msg.

		next if ($image_length == 0);

		if ( ($image_length < $id_length[0]) || ($image_length > $id_length[1]) || ($images[$i] !~ /^image_([0-9]{1,2})/) )
		{
			$$errors{'image_id'} = [substr($images[$i], 0, $prefix_length), 'length', $id_message];

			next;
		}

		$id				= $1;
		$image_length	= length($images[$i + 1]);

		# Ignore empty image file name without generating an error msg.

		next if ($image_length == 0);

		$image_length = length($images[$i + 2]);

		next if ( (length($images[$i + 1]) > $image_length[1]) || ($image_length > $image_length[1]) );

		if ( ($id >= 1) && ($id <= $$defaults{constants_table}{max_image_count}) )
		{
			# We put the individual images back into %$params for display if necessary (e.g. as errors).

			$key					= $images[$i];
			$$params{"${key}_file"} = $images[$i + 1];
			$$params{"${key}_text"} = $images[$i + 2];

			$self -> validator -> check_required({$images[$i] => "$images[$i + 1]$joiner$images[$i + 2]"}, $images[$i]);
		}
		else
		{
			$$errors{'image_id'} = [substr($images[$i], 0, $prefix_length), 'length', $id_message];
		}
	}

} # End of process_flower_images.

# -----------------------------------------------

sub process_flower_urls
{
	my($self, $app, $defaults, $errors, $joiner, $params) = @_;
	my($url_list)	= $$params{url_list};
	my(@urls)		= map{defined($_) ? $self -> trim($_) : ''} split(/$joiner/, $url_list);

	$app -> log -> debug('ValidateForm.process_flower_urls(...)');

	# Expected format of @urls:
	# o [$i]: A string id of the form 'url_\d+'.
	# o [$i + 1]: The url itself.

	my(@id_length)		= (5, 6); # (Min, Max).
	my($id_message)		= "$id_length[0] .. $id_length[1] chars";
	my($prefix_length)	= 20;
	my(@url_length)		= (5, 120); # (Min, Max).
	my($url_message)	= "$url_length[0] .. $url_length[1] chars";

	my($id);
	my($url_length);

	for (my($i) = 0; $i < $#urls; $i += 2)
	{
		$url_length = length($urls[$i]);

		# Ignore empty id without generating an error msg.

		next if ($url_length == 0);

		if ( ($url_length < $id_length[0]) || ($url_length > $id_length[1]) || ($urls[$i] !~ /^url_([0-9]{1,2})/) )
		{
			$$errors{'url_id'} = [substr($urls[$i], 0, $prefix_length), 'length', $id_message];

			next;
		}

		$id			= $1;
		$url_length	= length($urls[$i + 1]);

		# Ignore empty url without generating an error msg.

		next if ($url_length == 0);

		if ( ($url_length < $url_length[0]) || ($url_length > $url_length[1]) )
		{
			$$errors{$urls[$i]} = [substr($urls[$i + 1], 0, $id_length[1]), 'length', $url_message];

			next;
		}

		if ( ($id >= 1) && ($id <= $$defaults{constants_table}{max_url_count}) )
		{
			# We put the individual urls back into %$params for display if necessary (e.g. as errors).

			$$params{$urls[$i]} = $urls[$i + 1];

			$self -> validator -> check_url({$urls[$i] => $urls[$i + 1]}, $urls[$i]);
		}
		else
		{
			$$errors{'url_id'} = [substr($urls[$i], 0, $prefix_length), 'length', $id_message];
		}
	}

} # End of process_flower_urls.

# -----------------------------------------------
# This sub is duplicated from Database.pm because to call the orginal
# in each place it's used herein involves just too much complexity.

sub trim
{
	my($self, $value) = @_;
	$value	=~ s/^\s+//;
	$value	=~ s/\s+$//;
	$value	=~ s/\s{2,}/ /g;

	return $value;

} # End of trim.

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
