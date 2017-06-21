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

		$$params{_message}	= 'OK';
		$$params{_status}	= 0;
		my($joiner)			= $$defaults{joiner};
		my($attributes)		= $self -> process_flower_attributes($app, $joiner, $$params{attribute_list});
		my($images)			= $self -> process_flower_images($app, $joiner, $$params{image_list});
		my($notes)			= $self -> process_flower_notes($app, $joiner, $$params{note_list});
		my($urls)			= $self -> process_flower_urls($app, $joiner, $$params{url_list});
	}
	else
	{
		# Return 0 for success and 1 for failure.

		$$params{_message}	= 'Missing common name or scientific name';
		$$params{_status}	= 1;
	}

	return $params;

} # End of flower_details.

# -----------------------------------------------
# Returns a hashref.

sub process_flower_attributes
{
	my($self, $app, $joiner, $attribute_list) = @_;
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

	for $key (keys %$attributes)
	{
		$$attributes{$key} = join(', ', @{$$attributes{$key} });
	}

	$app -> log -> debug('Attributes: ' . Dumper($attributes) );

	return $attributes;

} # End of process_flower_attributes.

# -----------------------------------------------
# Returns a hashref of arrayrefs.

sub process_flower_images
{
	my($self, $app, $joiner, $image_list) = @_;
	my(@images)	= map{defined($_) ? $_ : ''} split(/$joiner/, $image_list);
	my($images)	= {};

	$app -> log -> debug('ValidateForm.process_flower_images(...)');

	for (my($i) = 0; $i < $#images; $i += 3)
	{
		$$images{$images[$i]} = [$images[$i + 1], $images[$i + 2] ];
	}

	$app -> log -> debug('Images: ' . Dumper($images) );

	return $images;

} # End of process_flower_images.

# -----------------------------------------------
# Returns a hashref.

sub process_flower_notes
{
	my($self, $app, $joiner, $note_list) = @_;
	my($notes)	= {map{defined($_) ? $_ : ''} split(/$joiner/, $note_list)};

	$app -> log -> debug('ValidateForm.process_flower_notes(...)');
	$app -> log -> debug('Notes: ' . Dumper($notes) );

	return $notes;

} # End of process_flower_notes.

# -----------------------------------------------
# Returns a hashref.

sub process_flower_urls
{
	my($self, $app, $joiner, $url_list) = @_;
	my($urls)	= {map{defined($_) ? $_ : ''} split(/$joiner/, $url_list)};

	$app -> log -> debug('ValidateForm.process_flower_urls(...)');

	for my $key (keys %$urls)
	{
		my($finder) = URI::Find::Schemeless->new(sub{my($url, $text) = @_; $$urls{$key} = $url; return $url});

		if ($$urls{$key})
		{
			$finder->find(\$$urls{$key});
		}
		else
		{
			$$urls{$key} = '';
		}
	}

	$app -> log -> debug('Urls: ' . Dumper($urls) );

	return $urls;

} # End of process_flower_urls.

# -----------------------------------------------

1;
