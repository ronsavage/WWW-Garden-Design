package WWW::Garden::Design::Util::ValidateForm;

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Dumper::Concise; # For Dumper().

use Moo;

use Types::Standard qw/Object/;

use WWW::Garden::Design::Util::Validator;

use utf8;

has validator =>
(
	default		=> sub{return WWW::Garden::Design::Util::Validator -> new},
	is			=> 'ro',
	isa			=> Object,
	required	=> 0,
);

our $VERSION = '0.95';

# -----------------------------------------------

sub flower_details
{
	my($self, $controller, $defaults) = @_;
	my($params) = $controller -> req -> params -> to_hash;
	my($app)	= $controller -> app;

	$app -> log -> debug("$_ => $$params{$_}") for sort keys %$params;

	if ($$params{common_name} && $$params{scientific_name})
	{
		# Return 0 for success and 1 for failure.

		my($csrf_ok)	= $controller -> session('csrf_token') eq $$params{csrf_token} ? 1 : 0;
		my($joiner)		= $$defaults{joiner};

		$self -> process_flower_attributes($app, $defaults, $joiner, $$params{attribute_list});
		$self -> process_flower_images($app, $defaults, $joiner, $$params{image_list});
		$self -> process_flower_notes($app, $defaults, $joiner, $$params{note_list});
		$self -> process_flower_urls($app, $defaults, $joiner, $$params{url_list});

		if ($csrf_ok == 1)
		{
			$$params{message}	= 'OK';
			$$params{status}	= 0;

			# Need to call error() on each name appearing in failed()'s output.

			$app -> log -> debug('Failed params: ' . Dumper($self -> validator -> validation -> failed) );
			$app -> log -> debug('Validated params: ' . Dumper($self -> validator -> validation -> output) );
		}
		else
		{
			# Return 0 for success and 1 for failure.

			$$params{message}	= 'Detected apparent CSRF activity';
			$$params{status}	= 1;
		}
	}
	else
	{
		# Return 0 for success and 1 for failure.

		$$params{message}	= 'Missing common name or scientific name';
		$$params{status}	= 1;
	}

	return $params;

} # End of flower_details.

# -----------------------------------------------

sub process_flower_attributes
{
	my($self, $app, $defaults, $joiner, $attribute_list) = @_;
	my(@attributes)	= split(/$joiner/, $attribute_list);
	my($attributes)	= {};

	$app -> log -> debug('ValidateForm.process_flower_attributes(...)');

	my($key);

	for (my($i) = 0; $i < $#attributes; $i += 2)
	{
		$key				= $attributes[$i] =~ s/_/ /gr;
		$$attributes{$key}	= [] if (! $$attributes{$key});

		push @{$$attributes{$key} }, $attributes[$i + 1];
	}

	my($field);
	my($temp_name);
	my($validated);

	for $key (keys %$attributes)
	{
		# 1: Test the name of the attribute.

		$temp_name = "attribute_$key";

		$self -> validator -> check_member({$temp_name => $key}, $temp_name, $$defaults{attribute_type_names});

		# 2: If that test worked, test all values of the attribute.

		$validated = $self -> validator -> validation -> output;

		if (exists $$validated{$temp_name})
		{
			for $field (@{$$attributes{$key} })
			{
				$temp_name = "attribute_${key}_$field";

				$self -> validator -> check_member({$temp_name => $field}, $temp_name, $$defaults{attribute_type_fields}{$key});
			}
		}
	}

} # End of process_flower_attributes.

# -----------------------------------------------

sub process_flower_images
{
	my($self, $app, $defaults, $joiner, $image_list) = @_;
	my(@images) = map{defined($_) ? $_ : ''} split(/$joiner/, $image_list);

	$app -> log -> debug('ValidateForm.process_flower_images(...)');

	# I'm currently accepting duplicate file names and duplicate descriptions.

	my(@field);

	for (my($i) = 0; $i < $#images; $i += 3)
	{
		next if (length($images[$i + 1]) == 0);

		@field = split(/_/, $images[$i]);

		$app -> log -> debug("Image. i: $i. id: $images[$i]. " . Dumper(@field) );

		if ( ($field[1] >= 1) && ($field[1] <= $$defaults{max_image_count}) )
		{
			$self -> validator -> check_required({$images[$i] => "$images[$i + 1]$joiner$images[$i + 2]"}, $images[$i]);
		}
	}

} # End of process_flower_images.

# -----------------------------------------------

sub process_flower_notes
{
	my($self, $app, $defaults, $joiner, $note_list) = @_;
	my(@notes) = map{defined($_) ? $_ : ''} split(/$joiner/, $note_list);

	$app -> log -> debug('ValidateForm.process_flower_notes(...)');

	# I'm currently accepting duplicate notes.

	my(@field);

	for (my($i) = 0; $i < $#notes; $i += 2)
	{
		next if (length($notes[$i + 1]) == 0);

		@field = split(/_/, $notes[$i]);

		if ( ($field[1] >= 1) && ($field[1] <= $$defaults{max_note_count}) )
		{
			$self -> validator -> check_required({$notes[$i] => $notes[$i + 1]}, $notes[$i]);
		}
	}

} # End of process_flower_notes.

# -----------------------------------------------

sub process_flower_urls
{
	my($self, $app, $defaults, $joiner, $url_list) = @_;
	my(@urls) = map{defined($_) ? $_ : ''} split(/$joiner/, $url_list);

	$app -> log -> debug('ValidateForm.process_flower_urls(...)');

	my($finder, @field);

	for (my($i) = 0; $i < $#urls; $i += 2)
	{
		next if (length($urls[$i + 1]) == 0);

		@field = split(/_/, $urls[$i]);

		if ( ($field[1] >= 1) && ($field[1] <= $$defaults{max_url_count}) )
		{
			$finder = URI::Find::Schemeless->new(sub{my($url, $text) = @_; return $url});

			$finder->find(\$urls[$i + 1]);

			$self -> validator -> check_required({$urls[$i] => $urls[$i + 1]}, $urls[$i]);
		}
	}

} # End of process_flower_urls.

# -----------------------------------------------

1;
