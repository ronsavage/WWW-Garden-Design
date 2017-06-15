package WWW::Garden::Design::Controller::AddFlower;

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper::Concise; # For Dumper().

use Date::Simple;

use Moo;

use URI::Find::Schemeless;

use utf8;

our $VERSION = '0.95';

# -----------------------------------------------
# https://github.com/kraih/mojo/wiki/Request-data.

sub display
{
	my($self) = @_;

	$self -> app -> log -> debug('AddFlower.display()');

	my($items) = $self->req->params->to_hash;

	$self -> app -> log -> debug("$_ => $$items{$_}") for sort keys %$items;

	if ($$items{common_name} && $$items{scientific_name})
	{
		my($joiner)		= qr/«»/;
		my($defaults)	= $self -> app -> defaults;
		my($attributes)	= $self -> process_attributes($joiner, $$items{attribute_list});	# Hashref.
		my($images)		= $self -> process_images($joiner, $$items{image_list});			# Hashref of arrayrefs.
		my($notes)		= {map{$_ eq '-' ? '' : $_} split($joiner, $$items{note_list})};	# Hashref.
		my($urls)		= $self -> process_urls($joiner, $$items{url_list});				# Hashref.

#		$$defaults{db} -> add_flower($items);

		$self -> stash(error	=> undef);
		$self -> stash(details	=> $self -> format($items) );
	}
	else
	{
		my($message) = 'Missing common name or scientific name';

		$self -> stash(error	=> $message);
		$self -> stash(details	=> undef);
		$self -> app -> log -> error($message);
	}

	$self -> render;

} # End of display.

# -----------------------------------------------

sub format
{
	my($self, $item) = @_;

	$self -> app -> log -> debug('Details.format(...)');

	my($html) = <<EOS;
<tr>
	<td>$$item{common_name}</td>
	<td>$$item{scientific_name}</td>
	<td>$$item{aliases}</td>
	<td>$$item{height}</td>
	<td>$$item{width}</td>
</tr>
EOS

	return $html;

} # End of format.

# -----------------------------------------------

sub process_attributes
{
	my($self, $joiner, $attribute_list)	= @_;
	my(@attributes)						= split($joiner, $attribute_list);
	my($attributes)						= {};

	$self -> app -> log -> debug('Details.process_attributes(...)');

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

	$self -> app -> log -> debug('Attributes: ' . Dumper($attributes) );

	return \$attributes;

} # End of process_attributes.

# -----------------------------------------------

sub process_images
{
	my($self, $joiner, $image_list)	= @_;
	my(@images)						= map{$_ eq '-' ? '' : $_} split($joiner, $image_list);
	my($images)						= {};

	$self -> app -> log -> debug('Details.process_images(...)');

	for (my($i) = 0; $i < $#images; $i += 3)
	{
		$$images{$images[$i]} = [$images[$i + 1], $images[$i + 2] ];
	}

	$self -> app -> log -> debug('Images: ' . Dumper($images) );

	return \$images;

} # End of process_images.

# -----------------------------------------------

sub process_urls
{
	my($self, $joiner, $url_list)	= @_;
	my($urls)						= {map{$_ eq '-' ? '' : $_} split($joiner, $url_list)};

	$self -> app -> log -> debug('Details.process_urls(...)');

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

	$self -> app -> log -> debug('Urls: ' . Dumper($urls) );

	return $urls;

} # End of process_urls.

# -----------------------------------------------

1;
